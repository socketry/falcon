# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2024, by Samuel Williams.

require_relative '../service/virtual'
require_relative 'paths'

require 'samovar'

module Falcon
	module Command
		# Implements the `falcon virtual` command. Designed for *deployment*.
		#
		# Manages a {Controller::Virtual} instance which is responsible for running the {Proxy} and {Redirect} instances.
		class Virtual < Samovar::Command
			self.description = "Run one or more virtual hosts with a front-end proxy."
			
			# The command line options.
			# @attribute [Samovar::Options]
			options do
				option '--bind-insecure <address>', "Bind redirection to the given hostname/address", default: "http://[::]:80"
				option '--bind-secure <address>', "Bind proxy to the given hostname/address", default: "https://[::]:443"
				
				option '-t/--timeout <duration>', "Specify the maximum time to wait for non-blocking operations.", type: Float, default: 30
			end
			
			# One or more paths to the configuration files.
			# @name paths
			# @attribute [Array(String)]
			many :paths
			
			def environment
				Async::Service::Environment.new(Falcon::Service::Virtual::Environment).with(
					verbose: self.parent&.verbose?,
					configuration_paths: self.paths,
					bind_insecure: @options[:bind_insecure],
					bind_secure: @options[:bind_secure],
					timeout: @options[:timeout],
				)
			end
			
			def configuration
				Async::Service::Configuration.new.tap do |configuration|
					configuration.add(self.environment)
				end
			end
			
			# Prepare the environment and run the controller.
			def call
				Console.logger.info(self) do |buffer|
					buffer.puts "Falcon Virtual v#{VERSION} taking flight!"
					buffer.puts "- To terminate: Ctrl-C or kill #{Process.pid}"
					buffer.puts "- To reload all sites: kill -HUP #{Process.pid}"
				end
				
				Async::Service::Controller.run(self.configuration)
			end
		end
	end
end
