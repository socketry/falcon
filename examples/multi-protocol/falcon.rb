#!/usr/bin/env falcon-host
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "falcon/environment/server"
require "falcon/environment/rack"
require "falcon/composite_server"
require "io/endpoint"
require "io/endpoint/named_endpoints"

# Define HTTP/1 endpoint configuration:
http1 = environment do
	include Falcon::Environment::Server

	scheme "http"
	protocol { Async::HTTP::Protocol::HTTP1 }

	endpoint do
		Async::HTTP::Endpoint.for(
			scheme,
			"localhost",
			port: 8080,
			protocol: protocol
		)
	end
end

# Define HTTP/2 endpoint configuration:
http2 = environment do
	include Falcon::Environment::Server

	scheme "http"
	protocol { Async::HTTP::Protocol::HTTP2 }

	endpoint do
		Async::HTTP::Endpoint.for(
			scheme,
			"localhost",
			port: 8090,
			protocol: protocol
		)
	end
end

# Main service that runs the same application on both endpoints:
service "multi-protocol" do
	include Falcon::Environment::Rack

	protocol_http1 { http1.with(middleware: self.middleware).evaluator }
	protocol_http2 { http2.with(middleware: self.middleware).evaluator }

	# Use NamedEndpoints to combine both endpoints:
	endpoint do
		endpoints = {
			protocol_http1: protocol_http1.endpoint,
			protocol_http2: protocol_http2.endpoint
		}

		IO::Endpoint::NamedEndpoints.new(endpoints)
	end

	# Create servers for each named endpoint:
	make_server do |bound_endpoint|
		servers = {}

		bound_endpoint.each do |name, endpoint|
			servers[name.to_s] = self[name].make_server(endpoint)
		end

		Falcon::CompositeServer.new(servers)
	end
end
