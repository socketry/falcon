# Streaming

Falcon supports streaming input and output, allowing you to send and receive data in real-time. This is particularly useful for applications that require live updates, such as chat applications or real-time dashboards.

## WebSockets

Falcon supports `Async::WebSocket` for client and server WebSocket connections. This allows for full-duplex communication channels over a single TCP connection, enabling real-time data exchange (including via HTTP/2).

```ruby
require 'async/websocket/adapters/rack'
require 'set'

run lambda {|env|
	Async::WebSocket::Adapters::Rack.open(env, protocols: ['ws']) do |connection|
		# Echo server:
		while message = connection.read
			connection.write(message)
			connection.flush
		end
	end or [404, {}, []]
}
```



## Server Sent Events

Falcon supports Server-Sent Events (SSE) for sending real-time updates to clients. This is useful for applications that need to push updates to the browser without requiring a full page reload.

```ruby
def server_sent_events?(env)
	env['HTTP_ACCEPT'].include?('text/event-stream')
end

run do |env|
	if server_sent_events?(env)
		body = proc do |stream|
			while true
				stream << "data: The time is #{Time.now}\n\n"
				sleep 1
			end
		rescue => error
		ensure
			stream.close(error)
		end
		
		[200, {'content-type' => 'text/event-stream'}, body]
	else
		# Else the request is for the index page, return the contents of index.html:
		[200, {'content-type' => 'text/html'}, [File.read('index.html')]]
	end
end
```
