#!/usr/bin/env ruby
# frozen_string_literal: true

# To run this example, you need to install the `sinatra` gem:
# $ bundle install
# $ bundle exec ./app.rb

require "sinatra/base"

class Server < Sinatra::Application
	set :server, :falcon
	
	# Hello World:
	get "/" do
		"Hello, World!"
	end
end

Server.run!
