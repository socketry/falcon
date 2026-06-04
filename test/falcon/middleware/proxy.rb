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
	
	let(:host) {proxy_for(authority: "www.google.com", endpoint: Async::HTTP::Endpoint.parse("https://www.google.com"))}
	
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
		
		expect(request.headers["forwarded"]).to be == ["for=127.0.0.1;proto=https"]
		expect(request.headers["x-forwarded-for"]).to be == ["127.0.0.1"]
		
		proxy.close
	end
	
	it "authors a forwarded header from the connection" do
		request = Protocol::HTTP::Request.new("https", "www.google.com", "GET", "/", nil, headers, nil)
		expect(request).to receive(:remote_address).and_return(Addrinfo.ip("127.0.0.1"))
		
		proxy.prepare_request(request, host)
		
		expect(request.headers["forwarded"]).to be == ["for=127.0.0.1;proto=https"]
		expect(request.headers["x-forwarded-for"]).to be == ["127.0.0.1"]
		expect(request.headers["x-forwarded-proto"]).to be == ["https"]
		expect(request.headers["via"]).not.to be_nil
	end
	
	it "strips client-supplied forwarding headers so they can't be spoofed" do
		headers = Protocol::HTTP::Headers[
			"x-forwarded-for" => "1.2.3.4",
			"x-forwarded-proto" => "https",
			"x-forwarded-host" => "evil.example.com",
			"x-forwarded-port" => "8443",
			"forwarded" => "for=9.9.9.9;proto=https",
		]
		request = Protocol::HTTP::Request.new("http", "www.google.com", "GET", "/", nil, headers, nil)
		expect(request).to receive(:remote_address).and_return(Addrinfo.ip("127.0.0.1"))
		
		proxy.prepare_request(request, host)
		
		# The spoofed values are stripped and replaced with Falcon's own.
		expect(request.headers["x-forwarded-for"]).to be == ["127.0.0.1"]
		expect(request.headers["x-forwarded-proto"]).to be == ["http"]
		expect(request.headers["forwarded"]).to be == ["for=127.0.0.1;proto=http"]
		
		# `x-forwarded-host` and `x-forwarded-port` are stripped and not re-authored, so they can't be spoofed.
		expect(request.headers["x-forwarded-host"]).to be_nil
		expect(request.headers["x-forwarded-port"]).to be_nil
	end
	
	it "doesn't let connection tokens strip authored forwarding headers" do
		headers = Protocol::HTTP::Headers[
			"connection" => "x-forwarded-for, x-forwarded-proto, forwarded, via",
		]
		request = Protocol::HTTP::Request.new("http", "www.google.com", "GET", "/", nil, headers, nil)
		expect(request).to receive(:remote_address).and_return(Addrinfo.ip("127.0.0.1"))
		proxy.prepare_request(request, host)
		expect(request.headers["connection"]).to be_nil
		expect(request.headers["x-forwarded-for"]).to be == ["127.0.0.1"]
		expect(request.headers["x-forwarded-proto"]).to be == ["http"]
		expect(request.headers["forwarded"]).to be == ["for=127.0.0.1;proto=http"]
		expect(request.headers["via"]).not.to be_nil
	end
	it "formats IPv6 addresses according to RFC 7239" do
		request = Protocol::HTTP::Request.new("https", "www.google.com", "GET", "/", nil, headers, nil)
		expect(request).to receive(:remote_address).and_return(Addrinfo.ip("::1"))
		
		proxy.prepare_request(request, host)
		
		# RFC 7239 requires IPv6 to be bracketed and quoted in `Forwarded`...
		expect(request.headers["forwarded"]).to be == ["for=\"[::1]\";proto=https"]
		# ...but `X-Forwarded-For` carries the bare address.
		expect(request.headers["x-forwarded-for"]).to be == ["::1"]
	end
	
	it "omits the client address when the remote address is unavailable" do
		request = Protocol::HTTP::Request.new("https", "www.google.com", "GET", "/", nil, headers, nil)
		expect(request).to receive(:remote_address).and_return(nil)
		
		proxy.prepare_request(request, host)
		
		# With no remote address there is nothing to author, so neither the legacy
		# `x-forwarded-for` nor a `for=` element in `forwarded` is emitted.
		expect(request.headers["x-forwarded-for"]).to be_nil
		expect(request.headers["forwarded"]).to be == ["proto=https"]
		
		# The scheme and via are still authored from connection-level facts.
		expect(request.headers["x-forwarded-proto"]).to be == ["https"]
		expect(request.headers["via"]).not.to be_nil
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
end
