#!/usr/bin/env ruby

require 'async'
require 'async/http/endpoint'
require 'async/http/client'

Async do |task|
	# endpoint = Async::HTTP::Endpoint.parse("https://rubyapi-org.herokuapp.com/2.7/o/string")
	endpoint = Async::HTTP::Endpoint.parse("https://rubyapi.org/2.7/o/string")
	client = Async::HTTP::Client.new(endpoint)
	
	response = client.get(endpoint.path, {
		'if-none-match' => 'W/"578a945b0772ae259625a9e66f06cdff"'
	})
	
	Async.logger.info(response, name: "headers") do |buffer|
		response.headers.each do |key, value|
			buffer.puts "#{key.rjust(40)}: #{value}"
		end
	end
	
	body = response.read
	
	Async.logger.info(response) {"Status: #{response.status} Body: #{body&.bytesize.inspect} bytes"}
	
	Async.logger.info(response, name: "trailer") do |buffer|
		response.headers.trailer.each do |key, value|
			buffer.puts "#{key.rjust(40)}: #{value}"
		end
	end
end
