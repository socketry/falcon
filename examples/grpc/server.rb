#!/usr/bin/env ruby
# frozen_string_literal: true

require "grpc"
require_relative "my_service_services_pb"

class Greeter < MyService::Greeter::Service
	def say_hello(hello_req, _unused_call)
		name = hello_req.name
		
		return MyService::HelloReply.new(message: "Hello, #{name}!")
	end
end

def main
	# Start the gRPC server
	server = GRPC::RpcServer.new
	server.add_http2_port("0.0.0.0:50051", :this_port_is_insecure)
	server.handle(Greeter)
	
	puts "Greeter Server is running at 0.0.0.0:50051..."
	server.run_till_terminated
end

# Run the server
main
