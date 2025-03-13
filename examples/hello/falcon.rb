#!/usr/bin/env falcon-host
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2024, by Samuel Williams.

require "falcon/environment/self_signed_tls"
require "falcon/environment/rack"
require "falcon/environment/supervisor"

service "hello.localhost" do
	include Falcon::Environment::SelfSignedTLS
	include Falcon::Environment::Rack
	
	scheme "http"
	protocol {Async::HTTP::Protocol::HTTP}
	
	# protocol {Async::HTTP::Protocol::HTTP1.new(
	# 	persistent: false,
	# 	maximum_line_size: 1024,
	# )}
	
	# endpoint do
	# 	Async::HTTP::Endpoint.for(scheme, "localhost", port: 9292, protocol: protocol)
	# end
	
	# append preload "preload.rb"
end
