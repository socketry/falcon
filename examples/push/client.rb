#!/usr/bin/env ruby
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2020, by Samuel Williams.

require 'async'
require 'async/http/endpoint'
require 'async/http/client'

Async do
	endpoint = Async::HTTP::Endpoint.parse("https://localhost:9292")
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
