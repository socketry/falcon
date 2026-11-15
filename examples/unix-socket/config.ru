#!/usr/bin/env falcon --verbose serve -c
# frozen_string_literal: true

run do |env|
	# This is not part of the rack specification, but is available when running under Falcon.
	request = env["protocol.http.request"]

	if request.method == "GET" && env["PATH_INFO"] == "/ping"
		[200, {}, ["PONG"]]
	elsif request.method == "POST" && env["PATH_INFO"] == "/reverse"
		body = request.body.read
		[200, {}, [body.reverse]]
	else
		[404, {}, ["Not Found"]]
	end
end
