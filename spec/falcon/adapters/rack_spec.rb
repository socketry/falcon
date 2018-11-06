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
require 'async/websocket/server'
require 'async/websocket/client'

RSpec.describe Falcon::Adapters::Rack do
	context '#unwrap_headers' do
		subject {described_class.new(lambda{})}
		
		let(:fields) {[['cookie', 'a=b'], ['cookie', 'x=y']]}
		let(:env) {Hash.new}
		
		it "should merge duplicate headers" do
			subject.unwrap_headers(fields, env)
			
			expect(env).to be == {'HTTP_COOKIE' => "a=b\nx=y"}
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
	
	context 'websockets', timeout: 1 do
		include_context Falcon::Server
		
		let(:endpoint) {Async::HTTP::URLEndpoint.parse('ws://127.0.0.1:9294', reuse_port: true)}
		
		let(:app) do
			lambda do |env|
				Async::WebSocket::Server.open(env) do |connection|
					while message = connection.next_message
						connection.send_message(message)
					end
				end
				
				[200, {}, []]
			end
		end
		
		let(:test_message) do
			{
				"user" => "test",
				"status" => "connected",
			}
		end
		
		it "can send and receive messages using websockets" do
			socket = endpoint.connect
			connection = Async::WebSocket::Client.new(socket, endpoint.url.to_s)
			
			connection.send_message(test_message)
			
			message = connection.next_message
			expect(message).to be == test_message
			
			connection.close
			socket.close
		end
	end
end
