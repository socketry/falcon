#!/usr/bin/env ruby
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "async/http/client"
require "async/http/endpoint"

addresses_path = File.expand_path(ENV.fetch("ADDRESSES_PATH", "addresses.txt"), __dir__)
addresses = File.readlines(addresses_path, chomp: true)

abort "No cluster addresses found in #{addresses_path}." if addresses.empty?

Sync do
	addresses.each do |address|
		endpoint = Async::HTTP::Endpoint.parse("http://#{address}")
		
		Async::HTTP::Client.open(endpoint) do |client|
			response = client.get("/")
			
			begin
				puts "#{address}: #{response.read}"
			ensure
				response.finish
			end
		end
	end
end
