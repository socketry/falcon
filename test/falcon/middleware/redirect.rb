# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Fletcher Dares.

require "falcon/middleware/redirect"

require "async/http/endpoint"
require "async/service/environment"

describe Falcon::Middleware::Redirect do
	let(:host) do
		Async::Service::Environment.build(authority: "www.example.com").evaluator
	end
	
	it "redirects to a default port without an explicit port" do
		redirect = subject.new(Falcon::Middleware::NotFound, {
			"www.example.com" => host,
		}, Async::HTTP::Endpoint.parse("https://localhost"))
		
		request = Protocol::HTTP::Request.new("http", "www.example.com", "GET", "/index", "HTTP/1.1", Protocol::HTTP::Headers["accept" => "*/*"], nil)
		response = redirect.call(request)
		
		expect(response.status).to be == 301
		expect(response.headers["location"]).to be == "https://www.example.com/index"
	end
end
