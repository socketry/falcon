# frozen_string_literal: true

require "grpc"
require_relative "my_service_services_pb"  # Adjust the path as needed
require_relative "my_service_pb"            # Adjust the path as needed

# Define the service handling
class GreeterService
	def say_hello(hello_req, _unused_call)
		name = hello_req.name
		
		return MyService::HelloReply.new(message: "Hello, #{name}!")
	end
end

run do |env|
	# Check if it's a gRPC request by looking for the Content-Type
	if env["CONTENT_TYPE"] == "application/grpc"
		# Get the input data
		input = env["rack.input"]
		prefix = input.read(5)
		request_body = input.read
		
		# Deserialize the request using the gRPC module for HelloRequest
		hello_request = MyService::HelloRequest.decode(request_body)
		
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
		headers = {
			"content-type" => "application/grpc+proto",
			"grpc-status" => "0"  # OK
		}
		
		[200, headers, [response_with_prefix]]
	else
		[400, { "Content-Type" => "text/plain" }, ["Unsupported Content-Type"]]
	end
end