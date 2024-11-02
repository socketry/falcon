#!/usr/bin/env falcon --verbose serve -c
# frozen_string_literal: true

require "rack/request"

KEY = "my cookie"

run do |env|
	request = Rack::Request.new(env)
	puts "My Cookie: #{request.cookies[KEY]}"
	puts "All Cookies: #{request.cookies}"
	
	headers = {}
	Rack::Utils.set_cookie_header!(headers, KEY, "bar")
	
	[200, headers, ["Hello World!"]]
end
