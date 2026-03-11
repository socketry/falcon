# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2026, by Samuel Williams.
# Copyright, 2018, by Mitsutaka Mimura.

require_relative "../server"
require_relative "../endpoint"
require_relative "../service/server"
require_relative "../environment/rackup"

require "async/service/configuration"
require "async/container"
require "async/http/client"
require "samovar"

module Falcon
	module Command
		# Implements the `falcon serve` command. Designed for *development*.
		#
		# Manages a {Controller::Serve} instance which is responsible for running applications in a development environment.
		class Serve < Samovar::Command
			self.description = "Run an HTTP server for development purposes."
			
			# The command line options.
			# @attribute [Samovar::Options]
			options do
				option "-b/--bind <address>", "Bind to the given hostname/address.", default: "https://localhost:9292"
				
				option "-p/--port <number>", "Override the specified port.", type: Integer
				option "-h/--hostname <hostname>", "Specify the hostname which would be used for certificates, etc."
				option "-t/--timeout <duration>", "Specify the maximum time to wait for non-blocking operations.", type: Float, default: nil
				
				option "-c/--config <path>", "Rackup configuration file to load.", default: "config.ru"
				option "--preload <path>", "Preload the specified path before creating containers."
				
				option "--cache", "Enable the response cache."
				
				option "--forked | --threaded | --hybrid", "Select a specific parallelism model.", key: :container, default: :forked
				
				option "-n/--count <count>", "Number of instances to start.", default: Async::Container.processor_count, type: Integer
				
				option "--forks <count>", "Number of forks (hybrid only).", type: Integer
				option "--threads <count>", "Number of threads (hybrid only).", type: Integer
				
				option "--[no]-restart", "Enable/disable automatic restart.", default: true
				option "--graceful-stop <timeout>", "Duration to wait for graceful stop.", type: Float, default: 1.0
				
				option "--health-check-timeout <duration>", "Duration to wait for health check.", type: Float, default: 30.0
			end
			
			# Extract container-related options from the command line options.
			# @returns [Hash] Options for container configuration.
			def container_options
				@options.slice(:count, :forks, :threads, :restart, :health_check_timeout)
			end
			
			# Extract endpoint-related options from the command line options.
			# @returns [Hash] Options for endpoint configuration.
			def endpoint_options
				@options.slice(:hostname, :port, :timeout)
			end
			
			# Get the name for the service, using hostname if available, otherwise the bind address.
			# @returns [String] The service name.
			def name
				@options[:hostname] || @options[:bind]
			end
			
			# Create the environment for the serve command.
			# @returns [Async::Service::Environment] The configured server environment.
			def environment
				Async::Service::Environment.new(Falcon::Environment::Server).with(
					Falcon::Environment::Rackup,
					root: Dir.pwd,
					
					verbose: self.parent&.verbose?,
					cache: @options[:cache],
					
					container_options: self.container_options,
					endpoint_options: self.endpoint_options,
					
					rackup_path: @options[:config],
					preload: [@options[:preload]].compact,
					url: @options[:bind],
					
					name: self.name,
					
					endpoint: ->{Endpoint.parse(url, **endpoint_options)}
				)
			end
			
			# Build the service configuration for the serve command.
			# @returns [Async::Service::Configuration] The service configuration.
			def configuration
				Async::Service::Configuration.new.tap do |configuration|
					configuration.add(self.environment)
				end
			end
			
			# The container class to use.
			def container_class
				case @options[:container]
				when :threaded
					return Async::Container::Threaded
				when :forked
					return Async::Container::Forked
				when :hybrid
					return Async::Container::Hybrid
				end
			end
			
			# The endpoint to bind to.
			def endpoint
				Endpoint.parse(@options[:bind], **endpoint_options)
			end
			
			# The endpoint suitable for a client to connect.
			def client_endpoint
				Async::HTTP::Endpoint.parse(@options[:bind], **endpoint_options)
			end
			
			# Create a new client suitable for accessing the application.
			def client
				Async::HTTP::Client.new(client_endpoint)
			end
			
			# Prepare the environment and run the controller.
			def call
				Console.info(self) do |buffer|
					buffer.puts "Falcon v#{VERSION} taking flight! Using #{self.container_class} #{self.container_options}."
					buffer.puts "- Running on #{RUBY_DESCRIPTION}"
					buffer.puts "- Binding to: #{self.endpoint}"
					buffer.puts "- To terminate: Ctrl-C or kill #{Process.pid}"
					buffer.puts "- To reload configuration: kill -HUP #{Process.pid}"
				end
				
				Async::Service::Controller.run(self.configuration, container_class: self.container_class, graceful_stop: @options[:graceful_stop])
			end
		end
	end
end
