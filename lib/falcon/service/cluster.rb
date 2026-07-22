# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require_relative "server"

module Falcon
	# @namespace
	module Service
		# A managed service for running Falcon workers with independently bound endpoints.
		class Cluster < Server
			# An immutable association between a worker and its bound endpoint.
			class Binding
				# Initialize a worker binding.
				# @parameter endpoint [IO::Endpoint::BoundEndpoint] The endpoint bound by the worker.
				def initialize(endpoint:)
					@endpoint = endpoint
					@addresses = endpoint.sockets.map{|socket| socket.to_io.local_address}.freeze
					freeze
				end
				
				# @attribute [IO::Endpoint::BoundEndpoint] The endpoint bound by the worker.
				attr_reader :endpoint
				
				# @attribute [Array(Addrinfo)] The addresses bound by the worker.
				attr_reader :addresses
			end
			
			# Cluster workers bind independently in their own process.
			def bind_endpoint
			end
			
			# Setup the service into the specified container.
			# @parameter container [Async::Container] The container to configure.
			def setup(container)
				container_options = @evaluator.container_options
				health_check_timeout = container_options[:health_check_timeout]
				
				container.run(**container_options) do |instance|
					clock = Async::Clock.start
					bound_endpoint = nil
					
					begin
						Async do
							evaluator = self.environment.evaluator
							server = nil
							
							health_checker(instance, health_check_timeout) do
								if server
									instance.name = format_title(evaluator, server)
								end
							end
							
							instance.status!("Preparing...")
							
							bound_endpoint = evaluator.endpoint.bound
							binding = Binding.new(endpoint: bound_endpoint)
							
							evaluator.prepare_worker!(instance, binding)
							emit_prepared(instance, clock)
							
							instance.status!("Running...")
							server = run(instance, evaluator, binding.endpoint)
							instance.name = format_title(evaluator, server)
							emit_running(instance, clock)
							
							instance.ready!
						end
					ensure
						bound_endpoint&.close
					end
				end
			end
		end
	end
end
