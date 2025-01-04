# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024-2025, by Samuel Williams.

require_relative "../../falcon"

require "kernel/sync"
require "io/endpoint/host_endpoint"

module Falcon
	module Rackup
		# The falcon adaptor for the `rackup` executable.
		class Handler
			# The default scheme.
			SCHEME = "http"
			
			# The name of the handler.
			def self.to_s
				"Falcon v#{Falcon::VERSION}"
			end
			
			# Generate an endpoint for the given `rackup` options.
			# @returns [::IO::Endpoint::HostEndpoint]
			def self.endpoint_for(**options)
				host = options[:Host] || "localhost"
				port = Integer(options[:Port] || 9292)
				
				return ::IO::Endpoint.tcp(host, port)
			end
			
			# Run the specified app using the given options:
			# @parameter app [Object] The rack middleware.
			def self.run(app, **options)
				app = ::Protocol::Rack::Adapter.new(app)
				
				Sync do |task|
					endpoint = endpoint_for(**options)
					server = ::Falcon::Server.new(app, endpoint, protocol: Async::HTTP::Protocol::HTTP1, scheme: SCHEME)
					
					server_task = server.run
					
					wrapper = self.new(server, task)
					
					yield wrapper if block_given?
					
					server_task.wait
				ensure
					server_task.stop
					wrapper.close
				end
			end
			
			def initialize(server, task)
				@server = server
				@task = task
				
				@notification = Thread::Queue.new
				
				@waiter = @task.async(transient: true) do
					@notification.pop
					
					@task&.stop
					@task = nil
				end
			end
			
			def stop
				@notification&.push(true)
			end
			
			def close
				@notification&.close
				@notification = nil
				
				@waiter&.stop
				@waiter = nil
			end
		end
	end
end
