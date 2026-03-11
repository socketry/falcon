#!/usr/bin/env async-service
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "falcon/environment/server"
require "async/service/supervisor/supervised"
require "async/service/supervisor/environment"
require "async/service/supervisor/utilization_monitor"

# A simple Rack application that demonstrates utilization monitoring.
class SimpleApp
	def call(env)
		# Simulate some work
		sleep(rand * 0.1)
		
		# Delay after response is sent - use to verify whether this counts toward active requests:
		if response_finished = env["rack.response_finished"]
			response_finished << proc{sleep 0.1}
		end
		
		return [200, {"content-type" => "text/plain"}, ["Hello, World!"]]
	end
end

service "web" do
	include Falcon::Environment::Server
	include Async::Service::Supervisor::Supervised
	
	# Define the middleware stack for this server
	middleware do
		Falcon::Server.middleware(SimpleApp.new, verbose: false, cache: false)
	end
	
	# Define the utilization schema for this service
	utilization_schema do
		{
			connections_total: :u64,
			connections_active: :u32,
			requests_total: :u64,
			requests_active: :u32,
		}
	end
end

service "supervisor" do
	include Async::Service::Supervisor::Environment
	
	# Configure the utilization monitor
	monitors do
		[
			Async::Service::Supervisor::UtilizationMonitor.new(
				path: File.expand_path("utilization.shm", __dir__),
				interval: 1.0
			)
		]
	end
end
