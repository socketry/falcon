# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2023, by Samuel Williams.
# Copyright, 2018, by Mitsutaka Mimura.

require_relative '../server'
require_relative '../endpoint'
require_relative '../controller/serve'

require 'async/container'

require 'async/io/trap'
require 'async/io/host_endpoint'
require 'async/io/shared_endpoint'
require 'async/io/ssl_endpoint'

require 'async/http/client'

require 'samovar'

require 'rack/builder'

require 'bundler'

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
				option '-b/--bind <address>', "Bind to the given hostname/address.", default: "https://localhost:9292"
				
				option '-p/--port <number>', "Override the specified port.", type: Integer
				option '-h/--hostname <hostname>', "Specify the hostname which would be used for certificates, etc."
				option '-t/--timeout <duration>', "Specify the maximum time to wait for non-blocking operations.", type: Float, default: nil
				
				option '-c/--config <path>', "Rackup configuration file to load.", default: 'config.ru'
				option '--preload <path>', "Preload the specified path before creating containers."
				
				option '--cache', "Enable the response cache."
				
				option '--forked | --threaded | --hybrid', "Select a specific parallelism model.", key: :container, default: :forked
				
				option '-n/--count <count>', "Number of instances to start.", default: Async::Container.processor_count, type: Integer
				
				option '--forks <count>', "Number of forks (hybrid only).", type: Integer
				option '--threads <count>', "Number of threads (hybrid only).", type: Integer
			end
			
			# Options for the {endpoint}.
			def endpoint_options
				@options.slice(:hostname, :port, :reuse_port, :timeout)
			end
			
			def environment
				Async::Service::Environment.build do
					include Falcon::Service::Server
					
					rackup_path @options[:config]
					
					container_options @options.slice(:count, :forks, :threads)
					
					preload @options[:preload]
					
					verbose @parent&.verbose?
					
					cache @options[:cache]
					
					endpoint do
						Endpoint.parse(@options[:bind], **endpoint_options)
					end
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
				Console.logger.info(self) do |buffer|
					buffer.puts "Falcon v#{VERSION} taking flight! Using #{self.container_class} #{self.container_options}."
					buffer.puts "- Binding to: #{self.endpoint}"
					buffer.puts "- To terminate: Ctrl-C or kill #{Process.pid}"
					buffer.puts "- To reload configuration: kill -HUP #{Process.pid}"
				end
				
				begin
					Bundler.require(:preload)
				rescue Bundler::GemfileNotFound
					# Ignore.
				end
				
				if Process.respond_to?(:warmup)
					Process.warmup
				elsif GC.respond_to?(:compact)
					3.times{GC.start}
					GC.compact
				end
				
				controller = Async::Service::Controller.new(container_class: self.container_class, environment: environment)
			end
		end
	end
end
