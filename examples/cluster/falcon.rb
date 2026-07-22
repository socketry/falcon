#!/usr/bin/env async-service
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "fileutils"
require "io/endpoint/unix_endpoint"
require "protocol/http/middleware"

require "falcon/environment/cluster"

socket_directory = File.expand_path(ENV.fetch("SOCKET_DIRECTORY", "sockets"), __dir__)
FileUtils.mkdir_p(socket_directory)

service "cluster" do
	include Falcon::Environment::Cluster
	
	count 2
	
	endpoint do
		worker_id = "#{Process.pid}-#{Thread.current.object_id}"
		socket_path = File.join(socket_directory, "#{worker_id}.ipc")
		transport = IO::Endpoint.unix(socket_path)
		
		Async::HTTP::Endpoint.parse(
			"http://localhost",
			transport,
			protocol: Async::HTTP::Protocol::HTTP1
		)
	end
	
	middleware do
		Protocol::HTTP::Middleware::HelloWorld
	end
end
