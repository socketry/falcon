#!/usr/bin/env falcon --verbose serve -c
# frozen_string_literal: true

require "async"

class RequestLogger
	def initialize(app)
		@app = app
	end
	
	def call(env)
		@app.call(env)
	end
end

use RequestLogger

run lambda {|env|
	start_time = Async::Clock.now
	
	server_timing = ->{
		"app;dur=#{Async::Clock.now - start_time}"
	}
	
	[
		200,
		[["trailer", "server-timing"], ["server-timing", server_timing]],
		["Hello World"]
	]
}
