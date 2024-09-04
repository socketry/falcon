# frozen_string_literal: true

require 'async/websocket'
require 'async/websocket/adapters/rack'

class App
	def handle_normal_request(env)
		[200, {'content-type' => 'text/plain'}, ["Hello World"]]
	end
	
	def call(env)
		Async::WebSocket::Adapters::Rack.open(env) do |connection|
			message = Protocol::WebSocket::TextMessage.generate({body: "Hello World"})
			
			# Simple echo server:
			while message = connection.read
				connection.write(message)
			end
		end or handle_normal_request(env)
	end
end

run App.new
