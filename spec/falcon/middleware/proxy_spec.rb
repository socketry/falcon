# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2020, by Samuel Williams.

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
