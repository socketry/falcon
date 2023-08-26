# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2022, by Samuel Williams.
# Copyright, 2019, by Bryan Powell.

require 'rack/handler'

require_relative '../../falcon'

require 'kernel/sync'
require 'async/io/host_endpoint'
require 'async/io/notification'

module Rack
	module Handler
		# The falcon adaptor for the `rackup` executable.
		class Falcon
			# The default scheme.
			SCHEME = "http"
			
			# Generate an endpoint for the given `rackup` options.
			# @returns [Async::IO::Endpoint]
			def self.endpoint_for(**options)
				host = options[:Host] || 'localhost'
				port = Integer(options[:Port] || 9292)
				
				return Async::IO::Endpoint.tcp(host, port)
			end
			
			# Run the specified app using the given options:
			# @parameter app [Object] The rack middleware.
			def self.run(app, **options)
				app = ::Protocol::Rack::Adapter.new(app)
						
				Sync do |task|
					endpoint = endpoint_for(**options)
					server = ::Falcon::Server.new(app, endpoint, protocol: Async::HTTP::Protocol::HTTP1, scheme: SCHEME)

					server_task = task.async do
						server.run.each(&:wait)
					end

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

				@notification = Async::IO::Notification.new

				@waiter = @task.async(transient: true) do
					@notification.wait

					@task&.stop
					@task = nil
				end
			end

			def stop
				@notification&.signal
			end

			def close
				@notification&.close
				@notification = nil

				@waiter&.stop
				@waiter = nil
			end
		end

		register :falcon, Falcon
	end
end
