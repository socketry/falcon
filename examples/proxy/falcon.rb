#!/usr/bin/env falcon-host
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024, by Samuel Williams.

require "falcon/environment/application"
require_relative "application"

service "proxy.localhost" do
	include Falcon::Environment::Application
	
	scheme "http"
	protocol {Async::HTTP::Protocol::HTTP}
	
	middleware do
		Application.new
	end
	
	endpoint do
		Async::HTTP::Endpoint.for(scheme, "localhost", port: 9292, protocol: protocol)
	end
end
