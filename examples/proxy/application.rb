#!/usr/bin/env falcon-host
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024, by Samuel Williams.

require 'async/http/client'

class Application
	# The endpoint we will proxy requests to:
	DEFAULT_PROXY_ENDPOINT = Async::HTTP::Endpoint.parse("http://localhost:3000")
	
	def initialize(endpoint = DEFAULT_PROXY_ENDPOINT)
		@client = Async::HTTP::Client.new(endpoint)
	end
	
	def call(request)
		@client.call(request)
	end
end
