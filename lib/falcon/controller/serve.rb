# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2023, by Samuel Williams.
# Copyright, 2020, by Michael Adams.

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
			# @parameter command [Command::Serve] The user-specified command-line options.
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
			
			# @returns [Protocol::HTTP::Middleware] an instance of the application to be served.
			def load_app
				@command.load_app
			end
			
			# Prepare the bound endpoint for the server.
			def start
				@endpoint ||= self.endpoint
				
				@bound_endpoint = Async do
					Async::IO::SharedEndpoint.bound(@endpoint)
				end.wait
				
				Console.logger.info(self) { "Starting #{name} on #{@endpoint.to_url}" }
				
				@debug_trap.ignore!
				
				super
			end
			
			# The name of the controller which is used for the process title.
			def name
				"Falcon Server"
			end
			
			# Setup the container with the application instance.
			# @parameter container [Async::Container::Generic]
			def setup(container)
				container.run(name: self.name, restart: true, **@command.container_options) do |instance|
					Async do |task|
						# Load one app instance per container:
						app = self.load_app
						
						task.async do
							if @debug_trap.install!
								Console.logger.info(instance) do
									"- Per-process status: kill -USR1 #{Process.pid}"
								end
							end
							
							@debug_trap.trap do
								Console.logger.info(self) do |buffer|
									task.reactor.print_hierarchy(buffer)
								end
							end
						end
						
						server = Falcon::Server.new(app, @bound_endpoint, protocol: @endpoint.protocol, scheme: @endpoint.scheme)
						
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
