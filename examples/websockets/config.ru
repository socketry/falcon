# frozen_string_literal: true

require 'async/websocket'
require 'async/websocket/adapters/rack'

class App
	def call(env)
		Async::WebSocket::Adapters::Rack.open(env) do |connection|
			message = Protocol::WebSocket::TextMessage.generate({body: "Hello World"})
			
			# Simple echo server:
			while message = connection.read
				connection.write(message)
			end
		end or [400, {}, []]
	end
end

run App.new
