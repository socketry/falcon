#!/usr/bin/env ruby
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2022, by Samuel Williams.

require 'async'
require 'async/http/endpoint'
require 'async/websocket/adapters/rack'

require 'falcon'

module WebSocketApp
	def self.call(env)
		Async::WebSocket::Adapters::Rack.open(env, protocols: %w[ws]) do |connection|
			while (message = connection.read)
				pp message
			end
		end or [200, [], ["Websocket only."]]
	end
end

Async do
	websocket_endpoint = Async::HTTP::Endpoint.parse('http://127.0.0.1:3000')
	
	app = Falcon::Server.middleware(WebSocketApp)
	
	server = Falcon::Server.new(app, websocket_endpoint)
	
	server.run.each(&:wait)
end
