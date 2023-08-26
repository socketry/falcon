# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2023, by Samuel Williams.

require 'rack'

require_relative 'server_context'

RSpec.describe Falcon::Server, timeout: 10 do
	include_context Falcon::Server
	
	context "http client" do
		let(:protocol) {Async::HTTP::Protocol::HTTP2}
		
		let(:app) do
			lambda do |env|
				request = Rack::Request.new(env)
				
				if request.post?
					[200, {}, ["POST: #{request.POST.inspect}"]]
				else
					[200, {}, ["Hello World"]]
				end
			end
		end
		
		context "GET /" do
			let!(:response) {client.get("/")}
			after {response.finish}
			
			it "generates successful response" do
				expect(response).to be_success
				expect(response.read).to be == "Hello World"
			end
		end
		
		context "HEAD /" do
			let!(:response) {client.head("/")}
			after {response.finish}
			
			it "generates successful response" do
				expect(response).to be_success
				expect(response.body).to be_empty
				expect(response.body).to have_attributes(length: 11)
			end
		end
		
		it "can POST application/x-www-form-urlencoded" do
			response = client.post("/", {'content-type' => 'application/x-www-form-urlencoded'}, ['hello=world'])
			
			expect(response).to be_success
			expect(response.read).to be == 'POST: {"hello"=>"world"}'
		end
		
		it "can POST multipart/form-data" do
			response = client.post("/", {'content-type' => 'multipart/form-data; boundary=multipart'}, ["--multipart\r\n", "Content-Disposition: form-data; name=\"hello\"\r\n\r\n", "world\r\n", "--multipart--"])
			
			expect(response).to be_success
			expect(response.read).to be == 'POST: {"hello"=>"world"}'
		end
	end
	
	context ::Rack::BodyProxy do
		let(:callback) {Proc.new{}}
		let(:content) {Array.new}
		
		let(:app) do
			lambda do |env|
				body = ::Rack::BodyProxy.new(content, &callback)
				
				[200, {}, body]
			end
		end
		
		it "should close non-empty body" do
			content << "Hello World"
			
			expect(callback).to receive(:call).and_call_original
			
			expect(client.get("/").read).to be == "Hello World"
		end
		
		it "should close empty body" do
			expect(callback).to receive(:call)
			
			expect(client.get("/").read).to be nil
		end
	end
	
	context "broken middleware" do
		let(:app) do
			lambda do |env|
				raise RuntimeError, "Middleware is broken"
			end
		end
		
		it "results in a 500 error if middleware raises an exception" do
			response = client.get("/", {})
			
			expect(response).to_not be_success
			expect(response.status).to be == 500
			expect(response.read).to be =~ /RuntimeError: Middleware is broken/
		end
	end
	
	context 'streaming response', timeout: nil do
		let(:app) do
			lambda do |env|
				body = proc do |stream|
					10.times do
						stream.write "Hello World!"
					end
				ensure
					stream.close
				end
				
				[200, {}, body]
			end
		end
		
		it "can stream response" do
			response = client.get("/")
			
			expect(response).to be_success
			expect(response.status).to be == 200
			expect(response.read).to be =~ /Hello World!/
		end
	end
end
