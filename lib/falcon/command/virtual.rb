# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2023, by Samuel Williams.

require_relative '../controller/virtual'
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
			
			include Paths
			
			# Prepare a new controller for the command.
			def controller
				Controller::Virtual.new(self)
			end
			
			# The URI to bind the `HTTPS` -> `falcon host` proxy.
			def bind_secure
				@options[:bind_secure]
			end
			
			# The URI to bind the `HTTP` -> `HTTPS` redirector.
			def bind_insecure
				@options[:bind_insecure]
			end
			
			# The connection timeout to use for incoming connections.
			def timeout
				@options[:timeout]
			end
			
			# Prepare the environment and run the controller.
			def call
				Console.logger.info(self) do |buffer|
					buffer.puts "Falcon Virtual v#{VERSION} taking flight!"
					buffer.puts "- To terminate: Ctrl-C or kill #{Process.pid}"
					buffer.puts "- To reload all sites: kill -HUP #{Process.pid}"
				end
				
				ENV['CONSOLE_LEVEL'] = 'debug'
				
				self.controller.run
			end
			
			# The insecure endpoint for connecting to the {Redirect} instance.
			def insecure_endpoint(**options)
				Async::HTTP::Endpoint.parse(@options[:bind_insecure], **options)
			end
			
			# The secure endpoint for connecting to the {Proxy} instance.
			def secure_endpoint(**options)
				Async::HTTP::Endpoint.parse(@options[:bind_secure], **options)
			end
			
			# An endpoint suitable for connecting to the specified hostname.
			def host_endpoint(hostname, **options)
				endpoint = secure_endpoint(**options)
				
				url = URI.parse(@options[:bind_secure])
				url.hostname = hostname
				
				return Async::HTTP::Endpoint.new(url, hostname: endpoint.hostname)
			end
		end
	end
end
