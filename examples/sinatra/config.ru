#!/usr/bin/env falcon --verbose serve -c

# Save this as `config.ru`, make it executable and then run it (or run falcon serve by hand)

# Middleware that responds to incoming requests:
require 'sinatra/base'
class MyApp < Sinatra::Base
	get "/" do
		response = Faraday.get 'http://sushi.com/nigiri/sake.json'
	end
end

# Build the middleware stack:
use MyApp # Then, it will get to Sinatra.
run lambda {|env| [404, {}, []]} # Bottom of the stack, give 404.
