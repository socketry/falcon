
require 'rack/handler'

require_relative '../../falcon'

module Rack
	module Handler
		module Falcon
			def self.endpoint_for(**options)
				host = options[:Host] || 'localhost'
				port = Integer(options[:Port] || 9292)
				
				return Async::IO::Endpoint.tcp(host, port)
			end
			
			def self.run(app, **options)
				endpoint = endpoint_for(**options)
				
				server = ::Falcon::Server.new(::Falcon::Adapters::Rack.new(app), endpoint)
				
				Async::Reactor.run do
					server.run
				end
			end
		end
		
		register :falcon, Falcon
	end
end
