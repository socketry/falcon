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

RSpec.describe Falcon::Server do
	include_context Async::RSpec::Reactor
	
	let(:config_path) {File.join(__dir__, "config.ru")}
	
	let(:server) {'falcon'} # of course :)
	let(:host) {'127.0.0.1'}
	let(:port) {9290}
	
	let(:protocol) {Async::HTTP::Protocol::HTTP1}
	let(:endpoint) {Async::IO::Endpoint.tcp(host, port)}
	let(:client) {Async::HTTP::Client.new(endpoint, protocol)}
	
	after(:each) {client.close}
	
	it "can start server" do
		pid = Process.spawn("rackup", "--server", server, "--host", host, "--port", String(port), config_path)
		
		sleep 1
		
		begin
			response = client.get("/", {})
		
			expect(response).to be_success
			expect(response.body).to be == "Hello World"
		ensure
			Process.kill :INT, pid
			Process.wait pid
		end
	end
end
