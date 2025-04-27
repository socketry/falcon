#!/usr/bin/env ruby
# frozen_string_literal: true

require "async/http"
require "async/http/internet/instance"

url = ARGV.shift || "https://localhost:9292"

Async do
	120.times do |index|
		Async::HTTP::Internet.post(url, body: "Hello, World!") do |response|
			Console.info(self, "Response:", index: index, version: response.version, status: response.status, headers: response.headers, body: response.read)
		end
		
		sleep 60
	end
end
