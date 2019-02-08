
require 'rack/handler'

require_relative '../../falcon'

require 'async/io/host_endpoint'

module Rack
	module Handler
		module Falcon
			SCHEME = "http".freeze
			
			def self.endpoint_for(**options)
				host = options[:Host] || 'localhost'
				port = Integer(options[:Port] || 9292)
				
				return Async::IO::Endpoint.tcp(host, port)
			end
			
			def self.run(app, **options)
				endpoint = endpoint_for(**options)
				
				app = ::Falcon::Adapters::Rack.new(app)
				app = ::Falcon::Adapters::Rewindable.new(app)
				
				server = ::Falcon::Server.new(app, endpoint, Async::HTTP::Protocol::HTTP1, SCHEME)
				yield server if block_given?

				Async::Reactor.run do
					server.run
				end
			end
		end
		
		register :falcon, Falcon
	end
end
