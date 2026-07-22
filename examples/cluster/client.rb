#!/usr/bin/env ruby
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "async/http/client"
require "async/http/endpoint"
require "io/endpoint/unix_endpoint"

socket_directory = File.expand_path(ENV.fetch("SOCKET_DIRECTORY", "sockets"), __dir__)
socket_paths = Dir.glob(File.join(socket_directory, "*.ipc")).select{|path| File.socket?(path)}

abort "No cluster sockets found in #{socket_directory}." if socket_paths.empty?

Sync do
	socket_paths.each do |socket_path|
		transport = IO::Endpoint.unix(socket_path)
		endpoint = Async::HTTP::Endpoint.parse(
			"http://localhost",
			transport,
			protocol: Async::HTTP::Protocol::HTTP1
		)
		
		Async::HTTP::Client.open(endpoint) do |client|
			response = client.get("/")
			
			begin
				puts "#{File.basename(socket_path)}: #{response.read}"
			ensure
				response.finish
			end
		end
	end
end
