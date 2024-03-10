# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2023, by Samuel Williams.

require 'falcon/middleware/proxy'
require 'falcon/service/proxy'

require 'sus/fixtures/async'
require 'async/http/client'
require 'async/http/endpoint'

describe Falcon::Middleware::Proxy do
	include Sus::Fixtures::Async::ReactorContext
	
	def proxy_for(**options)
		Falcon::Service::Proxy.new(
			Async::Service::Environment.build(**options)
		)
	end
	
	let(:proxy) do
		subject.new(Falcon::Middleware::BadRequest, {
			'www.google.com' => proxy_for(authority: "www.google.com", endpoint: Async::HTTP::Endpoint.parse('https://www.google.com')),
			'www.yahoo.com' => proxy_for(authority: "www.yahoo.com", endpoint: Async::HTTP::Endpoint.parse('https://www.yahoo.com')),
		})
	end
	
	let(:headers) {Protocol::HTTP::Headers['accept' => '*/*']}
	
	it 'can select client based on authority' do
		request = Protocol::HTTP::Request.new('https', 'www.google.com', 'GET', '/', nil, headers, nil)
		
		expect(request).to receive(:remote_address).and_return(Addrinfo.ip("127.0.0.1"))
		
		response = proxy.call(request)
		response.finish
		
		expect(response).not.to be(:failure?)
		
		expect(request.headers['x-forwarded-for']).to be == ["127.0.0.1"]
		
		proxy.close
	end
	
	it 'defers if no host is available' do
		request = Protocol::HTTP::Request.new('www.groogle.com', 'GET', '/', nil, headers, nil)
		
		response = proxy.call(request)
		response.finish
		
		expect(response).to be(:failure?)
		
		proxy.close
	end
end
