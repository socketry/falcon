#!/usr/bin/env falcon-host
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

require "falcon/environment/rack"
require_relative "../limited/limited"

service "limited.localhost" do
	include Falcon::Environment::Rack
	
	scheme "http"
	protocol do
		Async::HTTP::Protocol::HTTP1.new(
			persistent: false,
		)
	end
	
	# Extend the endpoint options to include the (connection) limited wrapper.
	endpoint_options do
		super().merge(
			protocol: protocol,
			wrapper: Limited::Wrapper.new
		)
	end
	
	count 1
	
	url "http://localhost:8080"
	
	endpoint do
		::Async::HTTP::Endpoint.parse(url).with(**endpoint_options)
	end
end
