#!/usr/bin/env falcon-host
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024, by Samuel Williams.

require "falcon/environment/self_signed_tls"
require "falcon/environment/rack"
require "async/service/supervisor"

service "websockets.localhost" do
	include Falcon::Environment::SelfSignedTLS
	include Falcon::Environment::Rack
end

service "supervisor" do
	include Async::Service::Supervisor::Environment
end
