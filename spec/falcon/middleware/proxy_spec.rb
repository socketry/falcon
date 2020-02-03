# frozen_string_literal: true

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

require 'falcon/middleware/proxy'

require 'async/http/client'
require 'async/http/endpoint'

RSpec.describe Falcon::Middleware::Proxy do
	include_context Async::RSpec::Reactor
	
	subject do
		described_class.new(Falcon::Middleware::BadRequest, {
			'www.google.com' => double(authority: "www.google.com", endpoint: Async::HTTP::Endpoint.parse('https://www.google.com')),
			'www.yahoo.com' => double(authority: "www.yahoo.com", endpoint: Async::HTTP::Endpoint.parse('https://www.yahoo.com')),
		})
	end
	
	let(:headers) {Protocol::HTTP::Headers['accept' => '*/*']}
	
	it 'can select client based on authority' do
		request = Protocol::HTTP::Request.new('https', 'www.google.com', 'GET', '/', nil, headers, nil)
		
		expect(request).to receive(:remote_address).and_return(Addrinfo.ip("127.0.0.1"))
		
		response = subject.call(request)
		response.finish
		
		expect(response).to_not be_failure
		
		expect(request.headers['x-forwarded-for']).to be == ["127.0.0.1"]
		
		subject.close
	end
	
	it 'defers if no host is available' do
		request = Protocol::HTTP::Request.new('www.groogle.com', 'GET', '/', nil, headers, nil)
		
		response = subject.call(request)
		response.finish
		
		expect(response).to be_failure
		
		subject.close
	end
end
