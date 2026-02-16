# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2025, by Samuel Williams.

require "falcon/command/virtual"

require "async/http"
require "protocol/http/request"

require "async/websocket/client"

VirtualCommand = Sus::Shared("falcon virtual") do
	let(:paths) {[
		File.expand_path("hello/falcon.rb", examples_root),
		File.expand_path("beer/falcon.rb", examples_root),
		File.expand_path("websockets/falcon.rb", examples_root),
	]}
	
	let(:examples_root) {File.expand_path("../../../examples", __dir__)}
	
	let(:options) {[]}
	
	let(:command) do
		subject[
			"--bind-insecure", "http://localhost:8080",
			"--bind-secure", "https://localhost:8443",
			*options,
			*paths,
		]
	end
	
	def around
		configuration = command.configuration
		controller = configuration.make_controller
		
		controller.start
		
		begin
			yield
		ensure
			controller.stop
		end
	end
	
	let(:insecure_client) {Async::HTTP::Client.new(command.insecure_endpoint, retries: 0)}
	
	with "no paths" do
		let (:paths) {[]}
		
		it "should still start correctly" do
			request = Protocol::HTTP::Request.new("https", "hello.localhost", "GET", "/index")
			
			Async do
				response = insecure_client.get("/index")
				
				expect(response).to be(:failure?)
			end
		end
	end
	
	it "gets redirected from insecure to secure endpoint" do
		request = Protocol::HTTP::Request.new("http", "hello.localhost", "GET", "/index")
		
		Async do
			response = insecure_client.call(request)
			
			expect(response).to be(:redirection?)
			expect(response.headers["location"]).to be == "https://hello.localhost:8443/index"
			
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
	
	with "websockets.localhost" do
		let(:host_endpoint) {command.host_endpoint("websockets.localhost").with(protocol: protocol)}
		
		it "can upgrade to websocket" do
			Sync do
				2.times do
					# Normal request:
					request = Protocol::HTTP::Request.new("https", "websockets.localhost", "GET", "/index")
					response = secure_client.call(request)
					
					expect(response).to be(:success?)
					expect(response.read).to be == "Hello World"
					
					# WebSocket request:
					Async::WebSocket::Client.connect(host_endpoint) do |connection|
						message = Protocol::WebSocket::TextMessage.generate({body: "Hello World"})
						
						connection.write(message)
						expect(connection.read).to be == message
					end
				end
			end
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
		it_behaves_like VirtualCommand, unique: "HTTP10"
	end
	
	with "HTTP/1.1" do
		let(:protocol) {Async::HTTP::Protocol::HTTP11}
		it_behaves_like VirtualCommand, unique: "HTTP11"
	end
	
	with "HTTP/2" do
		let(:protocol) {Async::HTTP::Protocol::HTTP2}
		it_behaves_like VirtualCommand, unique: "HTTP2"
	end
end
