#!/usr/bin/env ruby
# frozen_string_literal: true

require "grpc"
require_relative "my_service_services_pb"

def main
	# Create a stub for the Greeter service
	stub = MyService::Greeter::Stub.new("localhost:50051", :this_channel_is_insecure)
	
	# Create and populate a HelloRequest object
	request = MyService::HelloRequest.new(name: "World")
	
	# Call the SayHello method
	response = stub.say_hello(request)
	
	# Print the response message
	puts response.message
end

# Run the client
main
