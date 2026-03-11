#!/usr/bin/env -S ./bin/falcon virtual
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2026, by Samuel Williams.

require "falcon/environment/rack"
require "falcon/environment/self_signed_tls"
require "async/service/supervisor"

service "benchmark.localhost" do
	include Falcon::Environment::Rack
	include Falcon::Environment::SelfSignedTLS
end

service "supervisor" do
	include Async::Service::Supervisor::Environment
end
