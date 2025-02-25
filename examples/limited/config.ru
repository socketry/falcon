#!/usr/bin/env falcon --verbose serve -c
# frozen_string_literal: true

def limited_semaphore_token(request)
	if request.respond_to?(:connection)
		io = request.connection.stream.io
		
		if io.respond_to?(:token)
			return io.token
		end
	end
	
	return nil
end

run do |env|
	# This is not part of the rack specification, but is available when running under Falcon.
	request = env["protocol.http.request"]
	
	# There is no guarantee that there is a connection or that the connection has a token:
	token = limited_semaphore_token(request)
	
	if env["PATH_INFO"] == "/fast"
		if token
			# Keeping the connection alive here is problematic because if the next request is slow, it will "block the server" since we have relinquished the token already.
			token.release
			request.connection.persistent = false
		end
		
		# Simulated "fast / non-blocking" request:
		sleep(0.01)
	else
		# Simulated "slow / blocking" request:
		sleep(0.1)
	end
	
	[200, {}, ["Hello World"]]
end
