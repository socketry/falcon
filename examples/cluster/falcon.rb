#!/usr/bin/env async-service
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "async/service/supervisor"
require "async/service/supervisor/envoy"
require "falcon/environment/cluster"

service "cluster" do
	include Falcon::Environment::Cluster
	include Async::Service::Supervisor::Envoy::Supervised
	
	count 2
	
	def url
		"http://localhost:0"
	end
	
	middleware do
		rack_application = proc do |_env|
			worker_id = Process.pid.to_s
			body = "Hello from worker #{worker_id}!\n"
			
			[
				200,
				{
					"content-type" => "text/plain",
					"content-length" => body.bytesize.to_s,
					"x-worker-id" => worker_id,
				},
				[body],
			]
		end
		
		Falcon::Server.middleware(rack_application, cache: false)
	end
end

service "supervisor" do
	include Async::Service::Supervisor::Environment
	
	monitors do
		[
			Async::Service::Supervisor::Envoy::Monitor.new(
				bind: "http://127.0.0.1:18000",
			),
		]
	end
end
