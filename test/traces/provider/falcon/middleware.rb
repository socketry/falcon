# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "traces/provider/falcon/middleware"

require "async/http/endpoint"

describe "traces/provider/falcon/middleware" do
	let(:headers) {Protocol::HTTP::Headers["accept" => "*/*"]}
	
	def reset_trace_context!
		Traces.trace_context = nil
	end
	
	def expect_trace(name, expected_attributes)
		mock(Traces) do |mock|
			mock.wrap(:trace) do |original, actual_name, attributes: nil, &block|
				expect(actual_name).to be == name
				expect(attributes).to be == expected_attributes
				expect(block).not.to be == nil
				
				original.call(actual_name, attributes: attributes, &block)
			end
		end
	end
	
	it "provides traces for proxy middleware calls" do
		proxy = Falcon::Middleware::Proxy.new(Falcon::Middleware::BadRequest, {})
		request = Protocol::HTTP::Request.new("https", "www.example.com", "GET", "/", "HTTP/1.1", headers, nil)
		
		reset_trace_context!
		expect_trace("falcon.middleware.proxy.call", {
			"authority" => "www.example.com",
			"method" => "GET",
			"path" => "/",
			"version" => "HTTP/1.1",
		})
		
		response = proxy.call(request)
		
		expect(response.status).to be == 400
		expect(Traces.trace_context).to be_a(Traces::Context)
	end
	
	it "provides traces for redirect middleware calls" do
		redirect = Falcon::Middleware::Redirect.new(
			Falcon::Middleware::NotFound,
			{},
			Async::HTTP::Endpoint.parse("https://localhost"),
		)
		
		request = Protocol::HTTP::Request.new("http", "www.example.com", "GET", "/", "HTTP/1.1", headers, nil)
		
		reset_trace_context!
		expect_trace("falcon.middleware.redirect.call", {authority: "www.example.com"})
		
		response = redirect.call(request)
		
		expect(response.status).to be == 404
		expect(Traces.trace_context).to be_a(Traces::Context)
	end
end
