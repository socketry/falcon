#!/usr/bin/env falcon-host
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2025, by Samuel Williams.

require "falcon/environment/rack"
require "falcon/environment/supervisor"

SOCKET_PATH = "/tmp/falcon-unix-socket-example.sock"

# Custom service to handle socket cleanup
service "unix-socket" do
	include Falcon::Environment::Rack

	scheme "http"
	protocol {Async::HTTP::Protocol::HTTP}

	endpoint do
		Falcon::ProxyEndpoint.unix(
			SOCKET_PATH,
			scheme: scheme,
			protocol: protocol,
		)
	end
end
