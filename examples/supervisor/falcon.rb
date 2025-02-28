#!/usr/bin/env falcon-host
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2024, by Samuel Williams.

require "falcon/environment/self_signed_tls"
require "falcon/environment/rack"
require "falcon/environment/supervisor"

class MemoryMonitor < Async::Container::Supervisor::MemoryMonitor
	def memory_leak_detected(process_id, monitor)
		connections = @processes[process_id]
		
		# Note that if you use a multi-threaded or hybrid container, there will be multiple connections per process. We break after the first successful dump.
		connections.each do |connection|
			response = connection.call(do: :memory_dump, path: "memory-#{process_id}.json", timeout: 30)
			Console.info(self, "Memory dumped...", response: response)
			
			break
		end
		
		super
	end
end

service "hello.localhost" do
	include Falcon::Environment::SelfSignedTLS
	include Falcon::Environment::Rack
	
	scheme "http"
	protocol {Async::HTTP::Protocol::HTTP}
	
	endpoint do
		Async::HTTP::Endpoint.for(scheme, "localhost", port: 9292, protocol: protocol)
	end
	
	count 4
	
	url "http://localhost:8080"
	
	endpoint do
		::Async::HTTP::Endpoint.parse(url).with(**endpoint_options)
	end
	
	include Async::Container::Supervisor::Supervised
end

service "supervisor" do
	include Falcon::Environment::Supervisor
	
	monitors do
		[
			MemoryMonitor.new(interval: 10,
				# Per-supervisor (cluster) limit:
				total_size_limit: 80*1024*1024,
				# Per-process limit:
				maximum_size_limit: 20*1024*1024
			)
		]
	end
end
