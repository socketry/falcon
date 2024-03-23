#!/usr/bin/env async-service
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024, by Samuel Williams.

require 'falcon/service/server'

service "hello-server" do
	include Falcon::Service::Server
	
	middleware do
		::Protocol::HTTP::Middleware::HelloWorld
	end
end
