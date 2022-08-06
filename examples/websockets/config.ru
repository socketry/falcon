
require 'async/websocket'
require 'async/websocket/adapters/rack'

class App
	def call(env)
		Async::WebSocket::Adapters::Rack.open(env) do |connection|
			while true
				connection.write({message: "Hello World"})
				connection.flush
				sleep 1
			end
		end
	end
end

run App.new
