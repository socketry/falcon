# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2025, by Samuel Williams.
# Copyright, 2020, by Daniel Evans.

require "async/service/managed_service"
require "async/container/supervisor/supervised"
require "async/http/endpoint"

require_relative "../server"

module Falcon
	module Service
		class Server < Async::Service::ManagedService
			def initialize(...)
				super
				
				@bound_endpoint = nil
			end
			
			# Prepare the bound endpoint for the server.
			def start
				@endpoint = @evaluator.endpoint
				
				Sync do
					@bound_endpoint = @endpoint.bound
				end
				
				Console.logger.info(self) {"Starting #{self.name} on #{@endpoint}"}
				
				super
			end
			
			# Run the service logic.
			#
			# @parameter instance [Object] The container instance.
			# @parameter evaluator [Environment::Evaluator] The environment evaluator.
			# @returns [Falcon::Server] The server instance.
			def run(instance, evaluator)
				if evaluator.key?(:make_supervised_worker)
					Console.warn(self, "Async::Container::Supervisor is replaced by Async::Services::Supervisor, please update your service definition.")
					
					evaluator.make_supervised_worker(instance).run
				end
				
				server = evaluator.make_server(@bound_endpoint)
				
				Async do |task|
					server.run
					
					task.children.each(&:wait)
				end
				
				server
			end
			
			# Format the process title with server statistics.
			#
			# @parameter evaluator [Environment::Evaluator] The environment evaluator.
			# @parameter server [Falcon::Server] The server instance.
			# @returns [String] The formatted process title.
			private def format_title(evaluator, server)
				load = Fiber.scheduler.load.round(3)
				"#{evaluator.name} (#{server.statistics_string} L=#{load})"
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
