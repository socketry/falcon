#!/usr/bin/env falcon --verbose serve -c
# frozen_string_literal: true

require 'async'

class RequestLogger
	def initialize(app)
		@app = app
	end
	
	def call(env)
		logger = Console.logger.with(level: :debug)
		
		Async(logger: logger) do
			@app.call(env)
		end.wait
	end
end

# use RequestLogger

run lambda {|env| [200, {'cache-control' => 'max-age=10, public'}, ["Hello World"]]}
