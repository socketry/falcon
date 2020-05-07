# frozen_string_literal: true

# Copyright, 2019, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

require 'async/container/controller'
require 'async/io/trap'

require 'async/io/shared_endpoint'

module Falcon
	module Controller
		# A generic controller for serving an application.
		# Uses {Server} for handling incoming requests.
		class Serve < Async::Container::Controller
			# Initialize the server controller.
			# @param command [Command::Serve] The user-specified command-line options.
			def initialize(command, **options)
				@command = command
				
				@endpoint = nil
				@bound_endpoint = nil
				@debug_trap = Async::IO::Trap.new(:USR1)
				
				super(**options)
			end
			
			# Create the controller as specified by the command.
			# e.g. `Async::Container::Forked`.
			def create_container
				@command.container_class.new
			end
			
			# The endpoint the server will bind to.
			def endpoint
				@command.endpoint
			end
			
			# @return [Protocol::HTTP::Middleware] an instance of the application to be served.
			def load_app
				@command.load_app
			end
			
			# Prepare the bound endpoint for the server.
			def start
				@endpoint ||= self.endpoint
				
				@bound_endpoint = Async do
					Async::IO::SharedEndpoint.bound(@endpoint)
				end.wait
				
				@debug_trap.ignore!
				
				super
			end
			
			# The name of the controller which is used for the process title.
			def name
				"Falcon Server"
			end
			
			# Setup the container with the application instance.
			def setup(container)
				container.run(name: self.name, restart: true, **@command.container_options) do |instance|
					Async do |task|
						# Load one app instance per container:
						app = self.load_app
						
						task.async do
							if @debug_trap.install!
								Async.logger.info(instance) do
									"- Per-process status: kill -USR1 #{Process.pid}"
								end
							end
							
							@debug_trap.trap do
								Async.logger.info(self) do |buffer|
									task.reactor.print_hierarchy(buffer)
								end
							end
						end
						
						server = Falcon::Server.new(app, @bound_endpoint, @endpoint.protocol, @endpoint.scheme)
						
						server.run
						
						instance.ready!
						
						task.children.each(&:wait)
					end
				end
			end
			
			# Close the bound endpoint.
			def stop(*)
				@bound_endpoint&.close
				
				@debug_trap.default!
				
				super
			end
		end
	end
end
