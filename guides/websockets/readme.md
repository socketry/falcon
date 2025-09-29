# WebSockets

This guide explains how to use WebSockets with Falcon.

## Overview

Falcon supports WebSockets using the [async-websocket gem](https://github.com/socketry/async-websocket). This allows you to build real-time applications that can handle bidirectional communication between the server and clients.

~~~ruby
# config.ru

require "async/websocket/adapters/rack"

run do |env|
	Async::WebSocket::Adapters::Rack.open(env, protocols: ['ws']) do |connection|
		# Simple echo server:
		while message = connection.read
			connection.write(message)
			connection.flush
		end
	end or [200, {}, ["Hello World"]]
end
~~~
