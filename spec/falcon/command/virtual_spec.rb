# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2020, by Samuel Williams.

require 'falcon/command/virtual'

require 'async/http'
require 'protocol/http/request'

RSpec.shared_context Falcon::Command::Virtual do
	let(:examples_root) {File.expand_path("../../../examples", __dir__)}
	
	let(:options) {[]}
	
	let(:command) {
		described_class[
			"--bind-insecure", "http://localhost:8080",
			"--bind-secure", "https://localhost:8443",
			*options,
			*paths,
		]
	}
	
	around do |example|
		# Wait for the container to start...
		controller = command.controller
		
		controller.start
		
		begin
			example.run
		ensure
			controller.stop
		end
	end
	
	let(:insecure_client) {Async::HTTP::Client.new(command.insecure_endpoint, retries: 0)}
end

RSpec.describe Falcon::Command::Virtual do
	context "with example sites" do
		let(:paths) {[
			File.expand_path("hello/falcon.rb", examples_root),
			File.expand_path("beer/falcon.rb", examples_root),
		]}
		
		include_context Falcon::Command::Virtual
		
		it "gets redirected from insecure to secure endpoint" do
			request = Protocol::HTTP::Request.new("http", "hello.localhost", "GET", "/index")
			
			Async do
				response = insecure_client.call(request)
				
				expect(response).to be_redirection
				expect(response.headers['location']).to be == "https://hello.localhost:8443/index"
				
				response.close
			end
		end
		
		shared_examples_for Falcon::Command::Virtual do
			let(:secure_client) {Async::HTTP::Client.new(host_endpoint)}
			
			context "for hello.localhost" do
				let(:host_endpoint) {command.host_endpoint("hello.localhost").with(protocol: protocol)}
				
				it "gets valid response from secure endpoint" do
					request = Protocol::HTTP::Request.new("https", "hello.localhost", "GET", "/index")
					
					expect(request.authority).to be == "hello.localhost"
					
					Async do
						response = secure_client.call(request)
						
						expect(response).to be_success
						expect(response.read).to be == "Hello World"
						
						secure_client.close
					end.wait
				end
			end
			
			context "for beer.localhost" do
				let(:host_endpoint) {command.host_endpoint("beer.localhost").with(protocol: protocol)}
				
				it "can cancel request" do
					request = Protocol::HTTP::Request.new("https", "beer.localhost", "GET", "/index")
					
					Async do
						response = secure_client.call(request)
						
						expect(response).to be_success
						
						response.body.read
						response.close
						
						secure_client.close
					end.wait
				end
			end
			
			context "with short timeout" do
				let(:options) {["--timeout", "1"]}
				let(:host_endpoint) {command.host_endpoint("hello.localhost").with(protocol: protocol)}
				
				it "times out after lack of data" do
					request = Protocol::HTTP::Request.new("https", "hello.localhost", "GET", "/index")
					
					Async do |task|
						response = secure_client.call(request)
						connection = response.connection
						
						expect(response).to be_success
						expect(response.read).to be == "Hello World"
						
						task.sleep(2)
						
						# Try to reuse the connection:
						response = secure_client.call(request)
						response.read
						
						# The connection was actually timed out, so it's now marked as not being reusable:
						expect(connection).to_not be_reusable
					end.wait
				end
			end
		end
		
		context "using HTTP/1.0" do
			let(:protocol) {Async::HTTP::Protocol::HTTP10}
			include_examples Falcon::Command::Virtual
		end
		
		context "using HTTP/1.1" do
			let(:protocol) {Async::HTTP::Protocol::HTTP11}
			include_examples Falcon::Command::Virtual
		end
		
		context "using HTTP/2" do
			let(:protocol) {Async::HTTP::Protocol::HTTP2}
			include_examples Falcon::Command::Virtual
		end
	end
end
