# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2023, by Samuel Williams.
# Copyright, 2020, by Daniel Evans.

require_relative 'proxy'

require 'async/http/endpoint'
require 'async/io/shared_endpoint'

module Falcon
	module Service
		# Implements an application server using an internal clear-text proxy.
		class Application < Server
			def initialize(environment)
				super
				
				@bound_endpoint = nil
			end
			
			# The middleware that will be served by this application.
			# @returns [Protocol::HTTP::Middleware]
			def middleware
				# In a multi-threaded container, we don't want to modify the shared evaluator's cache, so we create a new evaluator:
				@environment.evaluator.middleware
			end
			
			# Number of instances to start.
			# @returns [Integer | nil]
			def count
			  @environment.evaluator.count
			end
			
			# Prepare the bound endpoint for the application instances.
			# Invoke {preload!} to load shared resources into the parent process.
			def start
				Console.logger.info(self) {"Binding to #{self.endpoint}..."}
				
				@bound_endpoint = Async::Reactor.run do
					Async::IO::SharedEndpoint.bound(self.endpoint)
				end.wait
				
				preload!
				
				super
			end
			
			# Setup instances of the application into the container.
			# @parameter container [Async::Container::Generic]
			def setup(container)
				protocol = self.protocol
				scheme = self.scheme
				
				run_options = {
					name: self.name,
					restart: true,
				}
				
				run_options[:count] = count unless count.nil?
				
				container.run(**run_options) do |instance|
					Async do |task|
						Console.logger.info(self) {"Starting application server for #{self.root}..."}
						
						server = Server.new(self.middleware, @bound_endpoint, protocol: protocol, scheme: scheme)
						
						server.run
						
						instance.ready!
						
						task.children.each(&:wait)
					end
				end
				
				super
			end
			
			# Close the bound endpoint.
			def stop
				@bound_endpoint&.close
				@bound_endpoint = nil
				
				super
			end
		end
	end
end
