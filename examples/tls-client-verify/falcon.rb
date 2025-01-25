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
	
	scheme "https"
	protocol {Async::HTTP::Protocol::HTTPS}
	
	ssl_context do
		super().tap do |context|
			context.verify_mode = OpenSSL::SSL::VERIFY_PEER
			
			context.verify_callback = proc do |verified, store_context|
				Console.warn(self, "Verified: #{verified}, error: #{store_context.error_string}")
				
				true
			end
		end
	end
	
	endpoint do
		Async::HTTP::Endpoint.for(scheme, "localhost", port: 9292, protocol: protocol, ssl_context: ssl_context)
	end
end
