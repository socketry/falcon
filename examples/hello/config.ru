#!/usr/bin/env falcon --verbose serve -c
# frozen_string_literal: true

require 'async'

Console.logger.debug!

class RequestLogger
	def initialize(app)
		@app = app
	end
	
	def call(env)
		@app.call(env)
	end
end

# use RequestLogger

run lambda {|env| [200, {'cache-control' => 'max-age=10, public'}, ["Hello World"]]}
