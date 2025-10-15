#!/usr/bin/env falcon-host
# frozen_string_literal: true

require "falcon/environment/rack"
require "async/redis"

service "localhost" do
	include Falcon::Environment::Rack
	endpoint {Async::HTTP::Endpoint.parse("http://0.0.0.0:8013")}
end

class MyService < Async::Service::Generic
	def setup(container)
		container.spawn do |instance|
			evaluator = @environment.evaluator
			Console.info(self, "Connecting to Redis at", evaluator.redis_endpoint)
			
			Async do
				client = Async::Redis::Client.new(evaluator.redis_endpoint)
				
				instance.ready!
				
				client.subscribe "status" do |context|
					Console.info(self, "Subscribed to Redis channel 'status'.")
					while response = context.listen
						Console.info(self, "Received event:", response)
					end
				end
			end
		end
	end
end

service "myservice" do
	service_class MyService
	
	redis_endpoint {Async::Redis::Endpoint.local}
end
