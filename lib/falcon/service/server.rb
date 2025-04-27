# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2025, by Samuel Williams.
# Copyright, 2020, by Daniel Evans.

require "async/service/generic"
require "async/container/supervisor/supervised"
require "async/http/endpoint"

require_relative "../server"

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
				health_check_timeout = container_options[:health_check_timeout]
				
				container.run(name: self.name, **container_options) do |instance|
					evaluator = @environment.evaluator
					
					Async do |task|
						if @environment.implements?(Async::Container::Supervisor::Supervised)
							evaluator.make_supervised_worker(instance).run
						end
						
						server = evaluator.make_server(@bound_endpoint)
						
						server.run
						
						instance.ready!
						
						if health_check_timeout
							Async(transient: true) do
								while true
									# We only update this if the health check is enabled. Maybe we should always update it?
									instance.name = "#{self.name} (#{server.statistics_string} L=#{Fiber.scheduler.load.round(3)})"
									sleep(health_check_timeout / 2)
									instance.ready!
								end
							end
						end
						
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
