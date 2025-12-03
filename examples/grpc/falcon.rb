#!/usr/bin/env falcon-host
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

require "falcon/environment/application"
require_relative "my_service_services_pb"

# Define the service handling
class GreeterService
	def say_hello(hello_req, _unused_call)
		name = hello_req.name
		
		return MyService::HelloReply.new(message: "Hello, #{name}!")
	end
end

class MyApplication
	def call(request)
		body = request.read
		prefix = body[0..5]
		message = body[5..-1]
		
		# Deserialize the request using the gRPC module for HelloRequest
		hello_request = MyService::HelloRequest.decode(message)
		
		# Create the service instance and call the method
		service = GreeterService.new
		response = service.say_hello(hello_request, nil)
		
		# Prepare the response
		encoded_response = response.to_proto
		
		# Create a length-prefixed response
		response_length = [encoded_response.bytesize].pack("N")  # Length in big-endian format
		compression_flag = "\x00"  # 0 for no compression
		response_with_prefix = compression_flag + response_length + encoded_response
		
		# Set the headers for the HTTP response
		headers = ::Protocol::HTTP::Headers.new
		headers["content-type"] = "application/grpc+proto"
		headers.trailer!
		headers["grpc-status"] = "0"
		
		return ::Protocol::HTTP::Response[200, headers, [response_with_prefix]]
	end
end

service "hello.localhost" do
	include Falcon::Environment::Application
	
	middleware do
		MyApplication.new
	end
	
	scheme "http"
	protocol {Async::HTTP::Protocol::HTTP2}
	
	endpoint do
		Async::HTTP::Endpoint.for(scheme, "localhost", port: 50051, protocol: protocol)
	end	
end
