# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require_relative "server"

module Falcon
	# @namespace
	module Service
		# A managed service for running Falcon workers with independently bound endpoints.
		class Cluster < Server
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
					
					# Route process signals through the reactor rather than an arbitrary request fiber.
					signal_reader, signal_writer = IO.pipe
					signal_handlers = [:INT, :TERM].to_h do |signal|
						[signal, Signal.trap(signal){signal_writer.write_nonblock(".", exception: false)}]
					end
					
					begin
						Async do |task|
							evaluator = self.environment.evaluator
							server = nil
							
							task.async(transient: true) do
								signal_reader.read(1)
								task.cancel
							end
							
							health_checker(instance, health_check_timeout) do
								if server
									instance.name = format_title(evaluator, server)
								end
							end
							
							instance.status!("Preparing...")
							
							bound_endpoint = evaluator.endpoint.bound
							evaluator.bound_endpoint = bound_endpoint
							
							evaluator.prepare!(instance)
							emit_prepared(instance, clock)
							
							instance.status!("Running...")
							server = run(instance, evaluator, bound_endpoint)
							instance.name = format_title(evaluator, server)
							emit_running(instance, clock)
							
							instance.ready!
						end
					ensure
						signal_handlers.each{|signal, handler| Signal.trap(signal, handler)}
						signal_reader.close
						signal_writer.close
						bound_endpoint&.close
					end
				end
			end
		end
	end
end
