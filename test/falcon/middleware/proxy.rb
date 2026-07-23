# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2024, by Samuel Williams.
# Copyright, 2026, by Fletcher Dares.

require "falcon/middleware/proxy"

require "sus/fixtures/async"
require "sus/fixtures/console/captured_logger"
require "async/http/client"
require "async/http/endpoint"
require "async/service/environment"

describe Falcon::Middleware::Proxy do
	include Sus::Fixtures::Async::ReactorContext
	include Sus::Fixtures::Console::CapturedLogger
	
	def proxy_for(**options)
		Async::Service::Environment.build(**options).evaluator
	end
	
	let(:proxy) do
		subject.new(Falcon::Middleware::BadRequest, {
			"www.google.com" => proxy_for(authority: "www.google.com", endpoint: Async::HTTP::Endpoint.parse("https://www.google.com")),
			"www.yahoo.com" => proxy_for(authority: "www.yahoo.com", endpoint: Async::HTTP::Endpoint.parse("https://www.yahoo.com")),
		})
	end
	
	let(:headers) {Protocol::HTTP::Headers["accept" => "*/*"]}
	
	it "removes proxy authorization by default" do
		headers = Protocol::HTTP::Headers[
			"authorization" => "Bearer application",
			"proxy-authorization" => "Basic proxy",
		]
		proxy.prepare_headers(headers)
		expect(headers["authorization"]).to be == "Bearer application"
		expect(headers["proxy-authorization"]).to be_nil
	end
	
	it "can select client based on authority" do
		request = Protocol::HTTP::Request.new("https", "www.google.com", "GET", "/", nil, headers, nil)
		
		expect(request).to receive(:remote_address).and_return(Addrinfo.ip("127.0.0.1"))
		
		response = proxy.call(request)
		response.finish
		
		expect(response).not.to be(:failure?)
		
		expect(request.headers["x-forwarded-for"]).to be == ["127.0.0.1"]
		
		proxy.close
	end
	
	it "defers if no host is available" do
		request = Protocol::HTTP::Request.new("www.groogle.com", "GET", "/", nil, headers, nil)
		
		response = proxy.call(request)
		response.finish
		
		expect(response).to be(:failure?)
		
		proxy.close
	end
	
	it "returns a bad gateway response if the upstream request fails" do
		request = Protocol::HTTP::Request.new("https", "www.google.com", "GET", "/", nil, headers, nil)
		client = Object.new
		
		expect(request).to receive(:remote_address).and_return(nil)
		expect(client).to receive(:call).and_raise(RuntimeError, "upstream failed")
		expect(proxy).to receive(:connect).and_return(client)
		
		response = proxy.call(request)
		
		expect(response.status).to be == 502
		expect(response.read).to be == "RuntimeError"
	end
	
	it "logs proxy request details when preparing requests" do
		request = Protocol::HTTP::Request.new("https", "www.google.com", "GET", "/", "HTTP/1.1", headers, nil)
		host = proxy_for(authority: "www.google.com", endpoint: Async::HTTP::Endpoint.parse("https://www.google.com"))
		
		expect(request).to receive(:remote_address).and_return(nil)
		
		proxy.prepare_request(request, host)
		
		expect_console.to have_logged(
			severity: be == :debug,
			subject: be == proxy,
			message: be(:include?, "Request authority: www.google.com"),
		)
	end
	
	it "strips forwarded headers before preparing requests" do
		headers = Protocol::HTTP::Headers[
			"forwarded" => "for=203.0.113.1;proto=http",
			"x-forwarded-for" => "203.0.113.1",
			"x-forwarded-proto" => "http",
			"x-forwarded-host" => "example.com",
			"x-forwarded-port" => "80",
			"x-forwarded-scheme" => "http",
			"x-forwarded-ssl" => "off",
			"x-real-ip" => "203.0.113.1",
			"client-ip" => "203.0.113.1",
		]
		request = Protocol::HTTP::Request.new("https", "www.google.com", "GET", "/", "HTTP/1.1", headers, nil)
		host = proxy_for(authority: "www.google.com", endpoint: Async::HTTP::Endpoint.parse("https://www.google.com"))
		
		expect(request).to receive(:remote_address).and_return(Addrinfo.ip("127.0.0.1"))
		
		proxy.prepare_request(request, host)
		
		expect(request.headers["forwarded"]).to be == ["for=127.0.0.1;proto=https"]
		expect(request.headers["x-forwarded-for"]).to be == ["127.0.0.1"]
		expect(request.headers["x-forwarded-proto"]).to be == ["https"]
		expect(request.headers["x-forwarded-host"]).to be_nil
		expect(request.headers["x-forwarded-port"]).to be_nil
		expect(request.headers["x-forwarded-scheme"]).to be_nil
		expect(request.headers["x-forwarded-ssl"]).to be_nil
		expect(request.headers["x-real-ip"]).to be_nil
		expect(request.headers["client-ip"]).to be_nil
	end
	
	it "allows forwarded header preparation to be overridden" do
		klass = Class.new(subject) do
			def prepare_forwarded_headers(headers)
			end
		end
		proxy = klass.new(Falcon::Middleware::BadRequest, {})
		headers = Protocol::HTTP::Headers[
			"forwarded" => "for=203.0.113.1;proto=http",
			"x-forwarded-for" => "203.0.113.1",
			"x-forwarded-proto" => "http",
		]
		request = Protocol::HTTP::Request.new("https", "www.google.com", "GET", "/", "HTTP/1.1", headers, nil)
		host = proxy_for(authority: "www.google.com", endpoint: Async::HTTP::Endpoint.parse("https://www.google.com"))
		
		expect(request).to receive(:remote_address).and_return(Addrinfo.ip("127.0.0.1"))
		
		proxy.prepare_request(request, host)
		
		expect(request.headers["forwarded"]).to be == ["for=203.0.113.1;proto=http", "for=127.0.0.1;proto=https"]
		expect(request.headers["x-forwarded-for"]).to be == ["203.0.113.1", "127.0.0.1"]
		expect(request.headers["x-forwarded-proto"]).to be == ["http", "https"]
	end
end
