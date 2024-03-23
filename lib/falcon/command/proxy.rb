# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2024, by Samuel Williams.

require_relative '../environment/proxy'
require_relative 'paths'

require 'samovar'

module Falcon
	module Command
		# Implements the `falcon proxy` command.
		#
		# Manages a {Controller::Proxy} instance which is responsible for proxing incoming requests.
		class Proxy < Samovar::Command
			self.description = "Proxy to one or more backend hosts."
			
			# The command line options.
			# @attribute [Samovar::Options]
			options do
				option '--bind <address>', "Bind to the given hostname/address", default: "https://[::]:443"
				
				option '-t/--timeout <duration>', "Specify the maximum time to wait for non-blocking operations.", type: Float, default: nil
			end
			
			# One or more paths to the configuration files.
			# @name paths
			# @attribute [Array(String)]
			many :paths
			
			include Paths
			
			def environment(**options)
				Async::Service::Environment.new(Falcon::Environment::Proxy).with(
					root: Dir.pwd,
					name: self.class.name,
					verbose: self.parent&.verbose?,
					url: @options[:bind],
					timeout: @options[:timeout],
					**options
				)
			end
			
			def configuration
				Configuration.for(
					self.environment(environments: super.environments)
				)
			end
			
			# Prepare the environment and run the controller.
			def call
				Console.logger.info(self) do |buffer|
					buffer.puts "Falcon Proxy v#{VERSION} taking flight!"
					buffer.puts "- Binding to: #{@options[:bind]}"
					buffer.puts "- To terminate: Ctrl-C or kill #{Process.pid}"
					buffer.puts "- To reload: kill -HUP #{Process.pid}"
					
					self.resolved_paths.each do |path|
						buffer.puts "- Loading configuration from #{path}"
					end
				end
				
				Async::Service::Controller.run(self.configuration)
			end
			
			# The endpoint to bind to.
			def endpoint(**options)
				Async::HTTP::Endpoint.parse(@options[:bind], timeout: @options[:timeout], **options)
			end
		end
	end
end
