# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2024, by Samuel Williams.
# Copyright, 2020, by Daniel Evans.

require 'async/service/generic'
require 'async/http/endpoint'

require_relative '../server'

module Falcon
	module Service
		class Server < Async::Service::Generic
			def initialize(...)
				super
				
				@bound_endpoint = nil
			end
			
			# Preload any resources specified by the environment.
			def preload!
				root = @evaluator.root
				
				if scripts = @evaluator.preload
					scripts = Array(scripts)
					
					scripts.each do |path|
						Console.logger.info(self) {"Preloading #{path}..."}
						full_path = File.expand_path(path, root)
						load(full_path)
					end
				end
			end
			
			# Prepare the bound endpoint for the server.
			def start
				@endpoint = @evaluator.endpoint
				
				Sync do
					@bound_endpoint = @endpoint.bound
				end
				
				preload!
				
				Console.logger.info(self) {"Starting #{self.name} on #{@endpoint}"}
				
				super
			end
			
			# Setup the container with the application instance.
			# @parameter container [Async::Container::Generic]
			def setup(container)
				container_options = @evaluator.container_options
				
				container.run(name: self.name, **container_options) do |instance|
					evaluator = @environment.evaluator
					
					Async do |task|
						server = Falcon::Server.new(evaluator.middleware, @bound_endpoint, protocol: @endpoint.protocol, scheme: @endpoint.scheme)
						
						server.run
						
						instance.ready!
						
						task.children.each(&:wait)
					end
				end
			end
			
			# Close the bound endpoint.
			def stop(...)
				if @bound_endpoint
					@bound_endpoint.close
					@bound_endpoint = nil
				end
				
				@endpoint = nil
				
				super
			end
		end
	end
end
