# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

require "async"

module Falcon
	# A composite server that manages multiple {Server} instances.
	#
	# This class coordinates running multiple server instances concurrently, allowing you to:
	# - Serve different applications on different endpoints.
	# - Use different configurations per server.
	# - Access statistics for each named server.
	# - Control all servers as a single unit.
	#
	# @example Create and run serveral applications.
	# 	require 'falcon/composite_server'
	# 	require 'falcon/server'
	# 	
	# 	# Create individual servers
	# 	servers = {
	# 	  "http" => Falcon::Server.new(app1, endpoint1),
	# 	  "https" => Falcon::Server.new(app2, endpoint2)
	# 	}
	# 	
	# 	# Create the composite server
	# 	composite = Falcon::CompositeServer.new(servers)
	# 	
	# 	# Run all servers
	# 	composite.run
	class CompositeServer
		# Initialize a composite server with the given server instances.
		#
		# @parameter servers [Hash(String, Falcon::Server)] A hash mapping server names to server instances.
		def initialize(servers)
			@servers = servers
		end
		
		# The individual server instances mapped by name.
		# @attribute [Hash(String, Falcon::Server)]
		attr :servers
		
		# Run the composite server, starting all individual servers.
		#
		# This method should be called within an Async context. It will run all server instances concurrently.
		#
		# @returns [Async::Task] The task running the servers. Call `stop` on the returned task to stop all servers.
		def run
			Async do |task|
				# Run each server - server.run creates its own Async block internally
				@servers.each do |name, server|
					task.async do
						begin
							# Call server.run which will handle its own async context
							server.run.wait
						rescue => error
							Console.logger.error(self) {"Server #{name.inspect} failed: #{error}"}
							raise
						end
					end
				end
				
				# Wait for all child tasks to complete
				task.children.each(&:wait)
			end
		end
		
		# Generates a human-readable string representing statistics for all servers.
		#
		# @returns [String] A string representing the current statistics for each server.
		def statistics_string
			if @servers.empty?
				"No servers running"
			else
				parts = @servers.map do |name, server|
					"#{name}: #{server.statistics_string}"
				end
				
				parts.join(", ")
			end
		end
		
		# Get detailed statistics for each server.
		#
		# @returns [Hash(String, String)] A hash mapping server names to their statistics strings.
		def detailed_statistics
			@servers.transform_values(&:statistics_string)
		end
	end
end
