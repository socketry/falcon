#!/usr/bin/env falcon serve -c

# Save this as `config.ru`, make it executable and then run it (or run falcon serve by hand)

# Middleware that responds to incoming requests:
require 'sinatra/base'
class MyApp < Sinatra::Base
	get "/" do
		"hello world"
	end
end

# Middleware that performs logging:
require 'async/logger'
Async.logger.level = Logger::DEBUG # Set log level to debug

class MyLogger
	def initialize(app)
		@app = app
	end
	
	def call(env)
		Async.logger.info "#{env['REQUEST_METHOD']} #{env['PATH_INFO']}"
		
		return @app.call(env)
	end
end

# Build the middleware stack:
use MyLogger # First, a request will pass through MyLogger#call.
use MyApp # Then, it will get to Sinatra.
run lambda {|env| [404, {}, []]} # Bottom of the stack, give 404.
