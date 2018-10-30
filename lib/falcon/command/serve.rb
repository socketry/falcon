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
				
				option '-c/--config <path>', "Rackup configuration file to load", default: 'config.ru'
				option '-n/--concurrency <count>', "Number of processes to start", default: Async::Container.hardware_concurrency, type: Integer
				
				option '--forked | --threaded', "Select a specific concurrency model", key: :container, default: :forked
			end
			
			def container_class
				case @options[:container]
				when :threaded
					require 'async/container/threaded'
					return Async::Container::Threaded
				when :forked
					require 'async/container/forked'
					return Async::Container::Forked
				end
			end
			
			def load_app(verbose)
				rack_app, options = Rack::Builder.parse_file(@options[:config])
				
				return Server.middleware(rack_app, verbose: verbose), options
			end
			
			def endpoint_options
				# Oh, for Hash#slice(keys...)
				options = {}
				
				if @options[:hostname]
					options[:hostname] = @options[:hostname]
				end
				
				if @options[:port]
					options[:port] = @options[:port]
				end
				
				return options
			end
			
			def client_endpoint
				Async::HTTP::URLEndpoint.parse(@options[:bind], **endpoint_options)
			end
			
			def client
				Async::HTTP::Client.new(client_endpoint)
			end
			
			def run(verbose = false)
				app, _ = load_app(verbose)
				
				endpoint = Endpoint.parse(@options[:bind], **endpoint_options)
				
				bound_endpoint = Async::Reactor.run do
					Async::IO::SharedEndpoint.bound(endpoint)
				end.result
				
				Async.logger.info "Falcon taking flight! Binding to #{endpoint} [#{container_class} with concurrency: #{@options[:concurrency]}]"
				
				debug_trap = Async::IO::Trap.new(:USR1)
				
				container_class.new(concurrency: @options[:concurrency], name: "Falcon Server") do |task, instance|
					task.async do
						debug_trap.install!
						Async.logger.info "Send `kill -USR1 #{Process.pid}` for detailed status :)"
						
						debug_trap.trap do
							task.reactor.print_hierarchy($stderr)
						end
					end
					
					server = Falcon::Server.new(app, bound_endpoint, endpoint.protocol, endpoint.scheme)
					
					server.run
					
					task.children.each(&:wait)
				end
			end
			
			def invoke(parent)
				container = run(parent.verbose?)
				
				container.wait
			end
		end
	end
end
