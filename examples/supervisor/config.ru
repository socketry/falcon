#!/usr/bin/env falcon --verbose serve -c
# frozen_string_literal: true

leaks = []

run do |env|
	request = Rack::Request.new(env)
	
	if size = request.params["leak"]
		Console.debug(self) {"Leaking #{size} bytes..."}
		leaks << " " * size.to_i
	end
	
	[200, {}, ["Hello World"]]
end
