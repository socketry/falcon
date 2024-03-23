#!/usr/bin/env async-service
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024, by Samuel Williams.

require 'falcon/environments/server'

service "hello-server" do
	include Falcon::Environments::Server
	
	middleware do
		::Protocol::HTTP::Middleware::HelloWorld
	end
end
