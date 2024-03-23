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
			
			def host_map(environments)
				hosts = {}
				
				environments.each do |environment|
					next unless environment.implements?(Falcon::Environment::Application)
					evaluator = environment.evaluator
					hosts[evaluator.authority] = evaluator
				end
				
				Console.info(self) {"Hosts: #{hosts}"}
				
				return hosts
			end
			
			def configuration
				configuration = super
				hosts = host_map(configuration.environments)
				
				Configuration.new.tap do |configuration|
					environment = self.environment(hosts: hosts)
					configuration.add(environment)
				end
			end
			
			# The container class to use.
			def container_class
				Async::Container.best_container_class
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
				
				Async::Service::Controller.run(self.configuration, container_class: self.container_class)
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
