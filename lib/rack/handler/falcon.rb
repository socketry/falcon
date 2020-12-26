# frozen_string_literal: true

require 'rack/handler'

require_relative '../../falcon'

require 'async/reactor'
require 'async/io/host_endpoint'

module Rack
	module Handler
		# The falcon adaptor for the `rackup` executable.
		module Falcon
			# The default scheme.
			SCHEME = "http"
			NAME = :falcon
			
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
				endpoint = endpoint_for(**options)
				
				app = ::Falcon::Adapters::Rack.new(app)
				app = ::Falcon::Adapters::Rewindable.new(app)
				
				server = ::Falcon::Server.new(app, endpoint, protocol: Async::HTTP::Protocol::HTTP1, scheme: SCHEME)
				yield server if block_given?
				
				Async::Reactor.run do
					server.run
				end
			end
		end
		
		register Falcon::NAME, Falcon
	end
end
