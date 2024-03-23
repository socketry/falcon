# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2024, by Samuel Williams.

require_relative '../environment/redirect'
require_relative 'paths'

require 'samovar'

module Falcon
	module Command
		class Redirect < Samovar::Command
			self.description = "Redirect from insecure HTTP to secure HTTP."
			
			# The command line options.
			# @attribute [Samovar::Options]
			options do
				option '--bind <address>', "Bind to the given hostname/address", default: "http://[::]:80"
				option '--redirect <address>', "Redirect using this address as a template.", default: "https://[::]:443"
				
				option '-t/--timeout <duration>', "Specify the maximum time to wait for non-blocking operations.", type: Float, default: nil
			end
			
			# One or more paths to the configuration files.
			# @name paths
			# @attribute [Array(String)]
			many :paths
			
			include Paths
			
			def environment(**options)
				Async::Service::Environment.new(Falcon::Environment::Redirect).with(
					root: Dir.pwd,
					name: self.class.name,
					verbose: self.parent&.verbose?,
					url: @options[:bind],
					redirect_url: @options[:redirect],
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
					buffer.puts "Falcon Redirect v#{VERSION} taking flight!"
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
			
			# The template endpoint to redirect to.
			def redirect_endpoint(**options)
				Async::HTTP::Endpoint.parse(@options[:redirect], **options)
			end
		end
	end
end
