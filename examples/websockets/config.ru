# frozen_string_literal: true

require 'async/websocket'
require 'async/websocket/adapters/rack'

class App
	def call(env)
		Async::WebSocket::Adapters::Rack.open(env) do |connection|
			message = Protocol::WebSocket::TextMessage.generate({body: "Hello World"})
			
			while true
				connection.write(message)
				connection.flush
				sleep 1
			end
		end
	end
end

run App.new
