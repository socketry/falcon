#!/usr/bin/env ruby

require 'async'
require 'async/http/url_endpoint'
require 'async/http/client'

Async do
	endpoint = Async::HTTP::URLEndpoint.parse("https://localhost:9292")
	client = Async::HTTP::Client.new(endpoint, Async::HTTP::Protocol::HTTP2::WithPush)
	
	response = client.get("/index.html")
	
	puts response.status
	puts response.read
	puts
	
	while promise = response.promises.dequeue
		promise.wait
		
		puts "** Promise: #{promise.request.path} **"
		puts promise.read
		puts
	end
ensure
	client.close
end

puts "Done"