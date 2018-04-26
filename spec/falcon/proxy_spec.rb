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

require 'falcon/proxy'

require 'async/http/client'
require 'async/http/url_endpoint'

RSpec.describe Falcon::Proxy do
	include_context Async::RSpec::Reactor
	
	subject do
		described_class.new(Falcon::BadRequest, {
			'www.google.com' => Async::HTTP::URLEndpoint.parse('https://www.google.com'),
			'www.yahoo.com' => Async::HTTP::URLEndpoint.parse('https://www.yahoo.com')
		})
	end
	
	it 'can select client based on authority' do
		request = Async::HTTP::Request.new('www.google.com', 'GET', '/', nil, {
			'accept' => '*/*',
		}, Async::HTTP::Body::Buffered.wrap([]))
		
		response = subject.call(request)
		response.finish
		
		expect(response).to_not be_failure
		
		subject.close
	end
	
	it 'defers if no host is available' do
		request = Async::HTTP::Request.new('www.groogle.com', 'GET', '/', nil, {
			'accept' => '*/*',
		}, Async::HTTP::Body::Buffered.wrap([]))
		
		response = subject.call(request)
		response.finish
		
		expect(response).to be_failure
		
		subject.close
	end
end
