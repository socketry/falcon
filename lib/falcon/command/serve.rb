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
require_relative '../verbose'
require_relative '../adapters/rack'

require 'async/container'
require 'async/io/trap'
require 'async/io/host_endpoint'
require 'async/io/shared_endpoint'

require 'async/http/middleware/builder'

require 'samovar'

require 'rack/builder'
require 'rack/server'

module Falcon
	module Command
		class Serve < Samovar::Command
			self.description = "Run an HTTP server."
			
			options do
				option '-c/--config <path>', "Rackup configuration file to load", default: 'config.ru'
				option '-n/--concurrency <count>', "Number of processes to start", default: Async::Container.hardware_concurrency, type: Integer
				
				option '-b/--bind <address>', "Bind to the given hostname/address", default: "tcp://localhost:9292"
				
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
				
				app = Async::HTTP::Middleware.build do
					if verbose
						use Verbose
					end
					
					use Async::HTTP::ContentEncoding
					use Adapters::Rewindable
					use Adapters::Rack
					
					run rack_app
				end
				
				return app, options
			end
			
			def run(verbose)
				app, options = load_app(verbose)
				
				endpoint = nil
				
				Async::Reactor.run do
					endpoint = Async::IO::SharedEndpoint.bound(
						Async::IO::Endpoint.parse(@options[:bind], reuse_port: true)
					)
				end
				
				Async.logger.info "Falcon taking flight! Binding to #{endpoint} [#{container_class} with concurrency: #{@options[:concurrency]}]"
				
				debug_trap = Async::IO::Trap.new(:USR1)
				
				container_class.new(concurrency: @options[:concurrency]) do |task|
					task.async do
						debug_trap.install!
						Async.logger.info "Send `kill -USR1 #{Process.pid}` for detailed status :)"
						
						debug_trap.trap do
							task.reactor.print_hierarchy($stderr)
						end
					end
					
					server = Falcon::Server.new(app, endpoint)
					
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
