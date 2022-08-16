# frozen_string_literal: true

require 'async/websocket'
require 'async/websocket/adapters/rack'

class App
	def call(env)
		Async::WebSocket::Adapters::Rack.open(env) do |connection|
			while true
				connection.write({message: "Hello World"})
				connection.flush
				
				# This is still needed for Ruby 2.7+ but is not needed in Ruby 3+
				Async::Task.current.sleep 1
			end
		end
	end
end

run App.new
