# frozen_string_literal: true

# Copyright, 2017, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'falcon/server'
require 'async/http/client'
require 'async/http/endpoint'
require 'async/rspec/reactor'
require 'async/rspec/ssl'

require 'async/io/ssl_socket'

RSpec.describe "Falcon::Server with SSL", timeout: 1 do
	include_context Async::RSpec::Reactor
	
	include_context Async::RSpec::SSL::ValidCertificate
	include_context Async::RSpec::SSL::VerifiedContexts
	
	let(:protocol) {Async::HTTP::Protocol::HTTPS}
	
	let(:server_endpoint) {Async::HTTP::Endpoint.parse("https://localhost:6365", ssl_context: server_context)}
	let(:client_endpoint) {Async::HTTP::Endpoint.parse("https://localhost:6365", ssl_context: client_context)}
	
	let(:server) {Falcon::Server.new(Falcon::Adapters::Rack.new(app), server_endpoint, protocol)}
	let(:client) {Async::HTTP::Client.new(client_endpoint, protocol)}
	after(:each) {client.close}
	
	around(:each) do |example|
		server_task = reactor.async do
			server.run
		end
		
		begin
			example.run
		ensure
			server_task.stop
		end
	end
	
	context "basic middleware" do
		let(:app) do
			lambda do |env|
				[200, {}, ["Hello World"]]
			end
		end
		
		it "client can get resource" do
			response = client.get("/", {})
			
			expect(response).to be_success
			expect(response.read).to be == "Hello World"
		end
	end
end
