# Copyright, 2018, by Samuel G. D. Williams. <http://www.codeotaku.com>
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
require 'async/websocket/adapters/rack'
require 'async/websocket/client'

require_relative 'early_hints_examples'
require_relative '../server_context'

RSpec.describe Falcon::Adapters::Rack do
	context '#unwrap_headers' do
		subject {described_class.new(lambda{})}
		
		let(:fields) {[['cookie', 'a=b'], ['cookie', 'x=y']]}
		let(:env) {Hash.new}
		
		it "should merge duplicate headers" do
			subject.unwrap_headers(fields, env)
			
			expect(env).to be == {'HTTP_COOKIE' => "a=b;x=y"}
		end
	end
	
	context 'HTTP_HOST', timeout: 1 do
		include_context Falcon::Server
		let(:protocol) {Async::HTTP::Protocol::HTTP2}
		
		let(:app) do
			lambda do |env|
				[200, {}, ["HTTP_HOST: #{env['HTTP_HOST']}"]]
			end
		end
		
		let(:response) {client.get("/")}
		
		it "get valid HTTP_HOST" do
			expect(response.read).to be == "HTTP_HOST: 127.0.0.1:9294"
		end
	end

	context 'Connection: close', timeout: 1 do
		include_context Falcon::Server
		let(:protocol) {Async::HTTP::Protocol::HTTP1}
		
		let(:app) do
			lambda do |env|
				[200, {'Connection' => 'close'}, ["Hello World!"]]
			end
		end
		
		let(:response) {client.get("/")}
		
		it "get valid response" do
			expect(response.headers).to be_empty
			expect(response.read).to be == "Hello World!"
		end
	end

	context 'REQUEST_URI', timeout: 1 do
		include_context Falcon::Server
		let(:protocol) {Async::HTTP::Protocol::HTTP2}

		let(:app) do
			lambda do |env|
				[200, {}, ["REQUEST_URI: #{env['REQUEST_URI']}"]]
			end
		end

		let(:response) {client.get("/?foo=bar")}

		it "get valid REQUEST_URI" do
			expect(response.read).to be == "REQUEST_URI: /?foo=bar"
		end
	end

	context "rack.url_scheme" do
		include_context Falcon::Server
		let(:protocol) {Async::HTTP::Protocol::HTTP1}

		let(:app) do
			lambda do |env|
				[200, {}, ["Scheme: #{env['rack.url_scheme'].inspect}"]]
			end
		end

		it 'defaults to http' do
			response = client.get('/')

			expect(response.read).to be == 'Scheme: "http"'
		end

		it 'responses X-Forwarded-Proto headers' do
			response = client.get('/', [["X-Forwarded-Proto", "https"]])

			expect(response.read).to be == 'Scheme: "https"'
		end
	end
	context "early hints" do
		it_behaves_like Falcon::Adapters::EarlyHints
	end

	context 'websockets', timeout: 1 do
		include_context Falcon::Server
		
		let(:endpoint) {Async::HTTP::Endpoint.parse('http://127.0.0.1:9294', reuse_port: true)}
		
		let(:app) do
			lambda do |env|
				Async::WebSocket::Adapters::Rack.open(env) do |connection|
					while message = connection.read
						connection.write(message)
					end
					
					connection.close
				end or [200, {}, []]
			end
		end
		
		let(:test_message) do
			{
				user: "test",
				status: "connected",
			}
		end
		
		it "can send and receive messages using websockets" do
			client = Async::WebSocket::Client.open(endpoint)
			connection = client.connect(endpoint.path)
			
			connection.write(test_message)
			
			message = connection.read
			expect(message).to be == test_message
			
			connection.close
		end
	end
end
