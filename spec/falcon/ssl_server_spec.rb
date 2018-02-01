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
require 'async/rspec/reactor'

require 'async/io/ssl_socket'

RSpec.describe "Falcon::Server with SSL" do
	include_context Async::RSpec::Reactor
	
	let(:key) {OpenSSL::PKey::RSA.new(2048)}
	
	let(:certificate) do
		subject = "/C=NZ/O=Test/OU=Test/CN=Test"
		
		certificate = OpenSSL::X509::Certificate.new
		certificate.subject = certificate.issuer = OpenSSL::X509::Name.parse(subject)
		certificate.not_before = Time.now - 3600
		certificate.not_after = Time.now + 3600
		certificate.public_key = key.public_key
		certificate.serial = 0x0
		certificate.version = 2
		
		certificate.sign key, OpenSSL::Digest::SHA1.new
	end
		
	let(:server_context) do
		OpenSSL::SSL::SSLContext.new.tap do |context|
			context.cert = certificate
			context.key = key
		end
	end
	
	let(:client_context) do
		OpenSSL::SSL::SSLContext.new.tap do |context|
			context.verify_mode = OpenSSL::SSL::VERIFY_NONE
		end
	end
	
	let(:endpoint) {Async::IO::Endpoint.tcp("localhost", 6365, reuse_port: true)}
	let(:server_endpoint) {Async::IO::SecureEndpoint.new(endpoint, ssl_context: server_context)}
	let(:client_endpoint) {Async::IO::SecureEndpoint.new(endpoint, ssl_context: client_context)}
	
	let(:server) {Falcon::Server.new(app, [server_endpoint])}
	let(:client) {Async::HTTP::Client.new([client_endpoint])}
	
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
			app = lambda do |env|
				[200, {}, ["Hello World"]]
			end
		end
		
		it "client can get resource" do
			response = client.get("/", {})
			
			expect(response).to be_success
			expect(response.body).to be == "Hello World"
		end
	end
end
