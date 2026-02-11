# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

require_relative "../server"
require_relative "../endpoint"
require_relative "../configuration"
require_relative "../service/server"
require_relative "../middleware/static"

require "async/container"
require "samovar"

module Falcon
	module Command
		# Implements the `falcon static` command. Designed for serving static files.
		#
		# Manages a static file server for the current directory.
		class Static < Samovar::Command
			self.description = "Serve static files from the current directory."
			
			# The command line options.
			# @attribute [Samovar::Options]
			options do
				option "-b/--bind <address>", "Bind to the given hostname/address.", default: "http://localhost:3000"
				
				option "-p/--port <number>", "Override the specified port.", type: Integer
				option "-h/--hostname <hostname>", "Specify the hostname which would be used for certificates, etc."
				option "-t/--timeout <duration>", "Specify the maximum time to wait for non-blocking operations.", type: Float, default: nil
				
				option "-r/--root <path>", "Root directory to serve static files from.", default: Dir.pwd
				option "-i/--index <filename>", "Index file to serve for directories.", default: "index.html"
				option "--[no]-directory-listing", "Enable/disable directory listings.", default: true
				
				option "--cache", "Enable the response cache."
				
				option "--forked | --threaded | --hybrid", "Select a specific parallelism model.", key: :container, default: :forked
				
				option "-n/--count <count>", "Number of instances to start.", default: 1, type: Integer
				
				option "--forks <count>", "Number of forks (hybrid only).", type: Integer
				option "--threads <count>", "Number of threads (hybrid only).", type: Integer
				
				option "--[no]-restart", "Enable/disable automatic restart.", default: true
				option "--graceful-stop <timeout>", "Duration to wait for graceful stop.", type: Float, default: 1.0
				
				option "--health-check-timeout <duration>", "Duration to wait for health check.", type: Float, default: 30.0
			end
			
			def container_options
				@options.slice(:count, :forks, :threads, :restart, :health_check_timeout)
			end
			
			def endpoint_options
				@options.slice(:hostname, :port, :timeout)
			end
			
			def name
				@options[:hostname] || @options[:bind]
			end
			
			def root_directory
				File.expand_path(@options[:root])
			end
			
			# Create a middleware stack for serving static files
			def middleware_app
				# Create a 404 fallback
				not_found_app = lambda do |request|
					Protocol::HTTP::Response[404, {'content-type' => 'text/plain'}, ['Not Found']]
				end
				
				# Create the static middleware
				Middleware::Static.new(
					not_found_app,
					root: root_directory,
					index: @options[:index],
					directory_listing: @options[:directory_listing]
				)
			end
			
			def environment
				static_middleware = middleware_app
				verbose_mode = self.parent&.verbose?
				cache_enabled = @options[:cache]
				
				Async::Service::Environment.new(Falcon::Environment::Server).with(
					root: root_directory,
					
					verbose: verbose_mode,
					cache: cache_enabled,
					
					container_options: self.container_options,
					endpoint_options: self.endpoint_options,
					
					url: @options[:bind],
					
					name: self.name,
					
					endpoint: ->{Endpoint.parse(url, **endpoint_options)},
					
					# Use our custom static middleware directly
					middleware: ->{ 
						::Protocol::HTTP::Middleware.build do
							if verbose_mode
								use Falcon::Middleware::Verbose
							end
							
							if cache_enabled
								use Async::HTTP::Cache::General
							end
							
							use ::Protocol::HTTP::ContentEncoding
							
							run static_middleware
						end
					}
				)
			end
			
			def configuration
				Configuration.new.tap do |configuration|
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
			
			# Prepare the environment and run the controller.
			def call
				Console.logger.info(self) do |buffer|
					buffer.puts "Falcon Static v#{VERSION} taking flight! Using #{self.container_class} #{self.container_options}."
					buffer.puts "- Running on #{RUBY_DESCRIPTION}"
					buffer.puts "- Serving files from: #{root_directory}"
					buffer.puts "- Index file: #{@options[:index]}"
					buffer.puts "- Binding to: #{self.endpoint}"
					buffer.puts "- To terminate: Ctrl-C or kill #{Process.pid}"
					buffer.puts "- To reload configuration: kill -HUP #{Process.pid}"
				end
				
				Async::Service::Controller.run(self.configuration, container_class: self.container_class, graceful_stop: @options[:graceful_stop])
			end
		end
	end
end
