# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2024, by Samuel Williams.

require 'falcon/command/virtual'

require 'async/http'
require 'protocol/http/request'

VirtualCommand = Sus::Shared("falcon virtual") do
	let(:paths) {[
		File.expand_path("hello/falcon.rb", examples_root),
		File.expand_path("beer/falcon.rb", examples_root),
	]}
	
	let(:examples_root) {File.expand_path("../../../examples", __dir__)}

	let(:options) {[]}
	
	let(:command) {
		subject[
			"--bind-insecure", "http://localhost:8080",
			"--bind-secure", "https://localhost:8443",
			*options,
			*paths,
		]
	}
	
	def around
		configuration = command.configuration
		controller = configuration.controller
		
		controller.start
		
		begin
			yield
		ensure
			controller.stop
		end
	end
	
	let(:insecure_client) {Async::HTTP::Client.new(command.insecure_endpoint, retries: 0)}
	
	it "gets redirected from insecure to secure endpoint" do
		request = Protocol::HTTP::Request.new("http", "hello.localhost", "GET", "/index")
		
		Async do
			response = insecure_client.call(request)
			
			expect(response).to be(:redirection?)
			expect(response.headers['location']).to be == "https://hello.localhost:8443/index"
			
			response.close
		end
	end
	
	let(:secure_client) {Async::HTTP::Client.new(host_endpoint)}
	
	with "hello.localhost" do
		let(:host_endpoint) {command.host_endpoint("hello.localhost").with(protocol: protocol)}
		
		it "gets valid response from secure endpoint" do
			request = Protocol::HTTP::Request.new("https", "hello.localhost", "GET", "/index")
			
			expect(request.authority).to be == "hello.localhost"
			
			Async do
				response = secure_client.call(request)
				
				expect(response).to be(:success?)
				expect(response.read).to be == "Hello World"
				
				secure_client.close
			end.wait
		end
	end
	
	with "beer.localhost" do
		let(:host_endpoint) {command.host_endpoint("beer.localhost").with(protocol: protocol)}
		
		it "can cancel request" do
			request = Protocol::HTTP::Request.new("https", "beer.localhost", "GET", "/index")
			
			Async do
				response = secure_client.call(request)
				
				expect(response).to be(:success?)
				
				response.body.read
				response.close
				
				secure_client.close
			end.wait
		end
	end
	
	with "short timeout" do
		let(:options) {["--timeout", "0.1"]}
		let(:host_endpoint) {command.host_endpoint("hello.localhost").with(protocol: protocol)}
		
		it "times out after lack of data" do
			request = Protocol::HTTP::Request.new("https", "hello.localhost", "GET", "/index")
			
			Async do |task|
				response = secure_client.call(request)
				connection = response.connection
				
				expect(response).to be(:success?)
				expect(response.read).to be == "Hello World"
				
				task.sleep(0.2)
				
				# Try to reuse the connection:
				response = secure_client.call(request)
				response.read
				
				# The connection was actually timed out, so it's now marked as not being reusable:
				expect(connection).not.to be(:reusable?)
			end.wait
		end
	end
end

describe Falcon::Command::Virtual do
	with "HTTP/1.0" do
		let(:protocol) {Async::HTTP::Protocol::HTTP10}
		it_behaves_like VirtualCommand
	end
	
	with "HTTP/1.1" do
		let(:protocol) {Async::HTTP::Protocol::HTTP11}
		it_behaves_like VirtualCommand
	end
	
	with "HTTP/2" do
		let(:protocol) {Async::HTTP::Protocol::HTTP2}
		it_behaves_like VirtualCommand
	end
end
