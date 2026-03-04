# frozen_string_literal: true

require "thread/local"
require "protocol/rack/adapter"

module Proxy
	extend Thread::Local
	
	ENDPOINT = Async::HTTP::Endpoint.parse("http://localhost:3000")
	
	def self.local
		Async::HTTP::Client.new(ENDPOINT)
	end
	
	def self.forward(env)
		# Generate a Protocol::HTTP::Request for the given env:
		request = ::Protocol::Rack::Request[env]
		
		Console.info("Forwarding request to #{request.method} #{request.path}", body: request.body)
		
		# if body = request.body
		# 	request.body = Protocol::HTTP::Body::Buffered.wrap(body)
		# end
		
		# Invoke the proxy client:
		response = self.instance.call(request)
		
		# Generate a Rack response:
		return Protocol::Rack::Adapter.make_response(env, response)
	end
end

run do |env|
	Proxy.forward(env)
end
