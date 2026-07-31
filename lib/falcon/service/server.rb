# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2026, by Samuel Williams.
# Copyright, 2020, by Daniel Evans.

require "async/service/managed/service"
require "async/http/endpoint"

require_relative "../listener"
require_relative "../server"

module Falcon
	# @namespace
	module Service
		# A managed service for running Falcon servers.
		class Server < Async::Service::Managed::Service
			# Initialize the server service.
			def initialize(...)
				super
				
				@listener = nil
			end
			
			# Build a listener from a configured and bound endpoint.
			# @parameter evaluator [Environment::Evaluator] The environment evaluator.
			# @parameter endpoint [Async::HTTP::Endpoint] The configured endpoint.
			# @parameter bound_endpoint [IO::Endpoint::BoundEndpoint] The bound endpoint.
			# @returns [Falcon::Listener] The bound listener.
			def make_listener(evaluator, endpoint, bound_endpoint)
				Listener.new(
					name: evaluator.name,
					scheme: endpoint.scheme,
					protocols: endpoint.protocol.names,
					endpoint: bound_endpoint,
				)
			end
			
			# Bind the endpoint used by each server worker.
			def bind_endpoint
				@endpoint = @evaluator.endpoint
				
				Sync do
					bound_endpoint = @endpoint.bound
					@listener = make_listener(@evaluator, @endpoint, bound_endpoint)
				end
				
				Console.info(self){"Starting #{self.name} on #{@endpoint}"}
			end
			
			# Prepare the bound endpoint for the server.
			def start
				bind_endpoint
				
				super
			end
			
			# Yield the listener used by a server worker.
			# @parameter evaluator [Environment::Evaluator] The environment evaluator.
			# @yields {|listener| ...} The listener used by the worker.
			# 	@parameter listener [Falcon::Listener] The bound listener.
			def with_listener(evaluator)
				yield @listener
			end
			
			# Setup the service into the specified container.
			# @parameter container [Async::Container] The container to configure.
			def setup(container)
				container_options = @evaluator.container_options
				health_check_timeout = container_options[:health_check_timeout]
				
				container.run(**container_options) do |instance|
					clock = Async::Clock.start
					evaluator = self.environment.evaluator
					
					with_listener(evaluator) do |listener|
						Async do
							server = nil
							
							health_checker(instance, health_check_timeout) do
								if server
									instance.name = format_title(evaluator, server)
								end
							end
							
							instance.status!("Preparing...")
							evaluator.prepare_worker!(instance, listener)
							emit_prepared(instance, clock)
							
							instance.status!("Running...")
							server = run(instance, evaluator, listener)
							instance.name = format_title(evaluator, server)
							emit_running(instance, clock)
							
							instance.ready!
						end
					end
				end
			end
			
			# Run the service logic.
			#
			# @parameter instance [Object] The container instance.
			# @parameter evaluator [Environment::Evaluator] The environment evaluator.
			# @parameter listener [Falcon::Listener] The listener used by this worker.
			# @returns [Falcon::Server] The server instance.
			def run(instance, evaluator, listener = @listener)
				if evaluator.respond_to?(:make_supervised_worker)
					Console.warn(self, "Async::Container::Supervisor is replaced by Async::Service::Supervisor, please update your service definition.")
					
					evaluator.make_supervised_worker(instance).run
				end
				
				server = evaluator.make_server(listener.endpoint)
				
				Async do |task|
					server.run
					
					task.children&.each(&:wait)
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
				if @listener
					@listener.close
					@listener = nil
				end
				
				@endpoint = nil
				
				super
			end
		end
	end
end
