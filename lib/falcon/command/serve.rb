# Copyright, 2017, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require_relative '../server'
require_relative '../endpoint'

require 'async/container'
require 'async/io/trap'
require 'async/io/host_endpoint'
require 'async/io/shared_endpoint'
require 'async/io/ssl_endpoint'

require 'samovar'

require 'rack/builder'
require 'rack/server'

module Falcon
	module Command
		class Serve < Samovar::Command
			self.description = "Run an HTTP server."
			
			options do
				option '-b/--bind <address>', "Bind to the given hostname/address", default: "https://localhost:9292"
				
				option '-p/--port <number>', "Override the specified port", type: Integer
				option '-h/--hostname <hostname>', "Specify the hostname which would be used for certificates, etc."
				option '-t/--timeout <duration>', "Specify the maximum time to wait for blocking operations.", type: Float, default: 60*10
				
				option '-c/--config <path>', "Rackup configuration file to load", default: 'config.ru'
				
				option '--forked | --threaded | --hybrid', "Select a specific parallelism model", key: :container, default: :forked
				
				option '-n/--count <count>', "Number of instances to start.", default: Async::Container.processor_count, type: Integer
				
				option '--forks <count>', "Number of forks (hybrid only).", type: Integer
				option '--threads <count>', "Number of threads (hybrid only).", type: Integer
			end
			
			def container_class
				case @options[:container]
				when :threaded
					return Async::Container::Threaded
				when :forked
					return Async::Container::Forked
				when :hybrid
					return Async::Container::Hybrid
				end
			end
			
			def load_app(verbose)
				rack_app, options = Rack::Builder.parse_file(@options[:config])
				
				return Server.middleware(rack_app, verbose: verbose), options
			end
			
			def slice_options(*keys)
				# TODO: Ruby 2.5 introduced Hash#slice
				options = {}
				
				keys.each do |key|
					if @options.key?(key)
						options[key] = @options[key]
					end
				end
				
				return options
			end
			
			def container_options
				slice_options(:count, :forks, :threads)
			end
			
			def endpoint_options
				slice_options(:hostname, :port, :reuse_port, :timeout)
			end
			
			def client_endpoint
				Async::HTTP::Endpoint.parse(@options[:bind], **endpoint_options)
			end
			
			def client
				Async::HTTP::Client.new(client_endpoint)
			end
			
			def run(verbose = false)
				app, _ = load_app(verbose)
				
				endpoint = Endpoint.parse(@options[:bind], **endpoint_options)
				
				bound_endpoint = Async::Reactor.run do
					Async::IO::SharedEndpoint.bound(endpoint)
				end.wait
				
				Async.logger.info(endpoint) do |buffer|
					buffer.puts "Falcon taking flight! Using #{container_class} #{container_options}"
					buffer.puts "- To terminate: Ctrl-C or kill #{Process.pid}"
				end
				
				debug_trap = Async::IO::Trap.new(:USR1)
				debug_trap.ignore!
				
				container = container_class.new
				
				container.run(name: "Falcon Server", restart: true, **container_options) do |task, instance|
					task.async do
						if debug_trap.install!
							Async.logger.info(instance) do
								"- Per-process status: kill -USR1 #{Process.pid}"
							end
						end
						
						debug_trap.trap do
							Async.logger.info(self) do |buffer|
								task.reactor.print_hierarchy(buffer)
							end
						end
					end
					
					server = Falcon::Server.new(app, bound_endpoint, endpoint.protocol, endpoint.scheme)
					
					server.run
					
					task.children.each(&:wait)
				end
				
				return container
			end
			
			def call
				container = run(parent.verbose?)
				
				container.wait
			end
		end
	end
end
