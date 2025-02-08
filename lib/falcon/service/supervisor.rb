# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2024, by Samuel Williams.

require "process/metrics"
require "json"

require "async/service/generic"

require "io/endpoint/bound_endpoint"
require "io/stream"

module Falcon
	module Service
		# Implements a host supervisor which can restart the host services and provide various metrics about the running processes.
		class Supervisor < Async::Service::Generic
			# Initialize the supervisor using the given environment.
			# @parameter environment [Build::Environment]
			def initialize(...)
				super
				
				@bound_endpoint = nil
			end
			
			# The endpoint which the supervisor will bind to.
			# Typically a unix pipe in the same directory as the host.
			def endpoint
				@evaluator.endpoint
			end
			
			# Restart the process group that the supervisor belongs to.
			def do_restart(message)
				# Tell the parent of this process group to spin up a new process group/container.
				# Wait for that to start accepting new connections.
				# Stop accepting connections.
				# Wait for existing connnections to drain.
				# Terminate this process group.
				signal = message[:signal] || :INT
				
				Process.kill(signal, Process.ppid)
			end
			
			# Capture process metrics relating to the process group that the supervisor belongs to.
			def do_metrics(message)
				Process::Metrics::General.capture(pid: Process.ppid, ppid: Process.ppid)
			end
			
			# Handle an incoming request.
			# @parameter message [Hash] The decoded message.
			def handle(message)
				case message[:please]
				when "restart"
					self.do_restart(message)
				when "metrics"
					self.do_metrics(message)
				end
			end
			
			# Bind the supervisor to the specified endpoint.
			def start
				Console.logger.info(self) {"Binding to #{self.endpoint}..."}
				
				@bound_endpoint = Sync{self.endpoint.bound}
				
				super
			end
			
			# Start the supervisor process which accepts connections from the bound endpoint and processes JSON formatted messages.
			# @parameter container [Async::Container::Generic]
			def setup(container)
				container_options = @evaluator.container_options
				health_check_timeout = container_options[:health_check_timeout]
				
				container.run(name: self.name, **container_options) do |instance|
					Async do
						@bound_endpoint.accept do |peer|
							stream = ::IO::Stream(peer)
							
							while message = stream.read_until("\0")
								response = handle(JSON.parse(message, symbolize_names: true))
								stream.puts(response.to_json, separator: "\0")
							end
						end
						
						instance.ready!
						
						if health_check_timeout
							Async(transient: true) do
								while true
									sleep(health_check_timeout / 2)
									instance.ready!
								end
							end
						end
					end
				end
				
				super
			end
			
			# Release the bound endpoint.
			def stop
				@bound_endpoint&.close
				@bound_endpoint = nil
				
				super
			end
			
			def invoke(command)
				@bound_endpoint.local_address_endpoint.connect do |peer|
					stream = ::IO::Stream(peer)
					
					stream.puts(command.to_json, separator: "\0")
					
					response = JSON.parse(stream.read_until("\0"), symbolize_names: true)
					
					return response
				end
			end
		end
	end
end
