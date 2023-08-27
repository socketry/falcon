# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2023, by Samuel Williams.

require 'samovar'
require 'async'
require 'json'

require 'async/io/stream'
require 'async/io/unix_endpoint'

module Falcon
	module Command
		# Implements the `falcon supervisor` command.
		#
		# Talks to an instance of the supervisor to issue commands and print results.
		class Supervisor < Samovar::Command
			self.description = "Control and query a specific supervisor."
			
			# The command line options.
			# @attribute [Samovar::Options]
			options do
				option "--path <path>", "The control IPC path.", default: "supervisor.ipc"
			end
			
			# Implements the `falcon supervisor restart` command.
			class Restart < Samovar::Command
				self.description = "Restart the process group."
				
				# Send the restart message to the supervisor.
				def call(stream)
					stream.puts({please: 'restart'}.to_json, separator: "\0")
				end
			end
			
			# Implements the `falcon supervisor metrics` command.
			class Metrics < Samovar::Command
				self.description = "Show metrics about the falcon processes."
				
				# Send the metrics message to the supervisor and print the results.
				def call(stream)
					stream.puts({please: 'metrics'}.to_json, separator: "\0")
					response = JSON.parse(stream.gets("\0"), symbolize_names: true)
					
					pp response
				end
			end
			
			# The nested command to execute.
			# @name nested
			# @attribute [Command]
			nested :command, {
				'restart' => Restart,
				'metrics' => Metrics,
			}, default: 'metrics'
			
			# The endpoint the supervisor is bound to.
			def endpoint
				Async::IO::Endpoint.unix(@options[:path])
			end
			
			# Connect to the supervisor and execute the requested command.
			def call
				Async do
					endpoint.connect do |socket|
						stream = Async::IO::Stream.new(socket)
						
						@command.call(stream)
					end
				end
			end
		end
	end
end
