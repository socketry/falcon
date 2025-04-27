#!/usr/bin/env falcon-host
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

require "falcon/environment/rack"
require_relative "limited"

service "limited.localhost" do
	include Falcon::Environment::Rack
	
	scheme "http"
	protocol {Async::HTTP::Protocol::HTTP}
	
	# Extend the endpoint options to include the (connection) limited wrapper.
	endpoint_options do
		super().merge(wrapper: Limited::Wrapper.new)
	end
	
	count 2
	
	url "http://localhost:8080"
	
	endpoint do
		::Async::HTTP::Endpoint.parse(url).with(**endpoint_options)
	end
end
