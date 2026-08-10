#!/usr/bin/env falcon --verbose serve -c
# frozen_string_literal: true

require 'async'
require 'uri'
require 'net/http'

class App
	def initialize
		# Thread.current.scheduler = nil
	end
	
	def call(env)
		uri = URI("https://www.codeotaku.com/code/hello")
		
		body = Net::HTTP.get(uri)
		
		return [200, {'cache-control' => 'max-age=10, public'}, [body]]
	end
end

run App.new
