# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "falcon/middleware/verbose"

require "sus/fixtures/async"
require "sus/fixtures/console/captured_logger"

describe Falcon::Middleware::Verbose do
	include Sus::Fixtures::Async::ReactorContext
	include Sus::Fixtures::Console::CapturedLogger
	
	let(:app) do
		Protocol::HTTP::Middleware.for do |request|
			Protocol::HTTP::Response[200, {"content-type" => "text/plain", "set-cookie" => "session=xyz"}, ["ok"]]
		end
	end
	
	let(:verbose) {subject.new(app)}
	
	let(:headers) do
		Protocol::HTTP::Headers[
			"accept" => "*/*",
			"authorization" => "Bearer secret",
			"proxy-authorization" => "Basic cHJveHk6aHVudGVyMg==",
			"cookie" => "session=abc",
		]
	end
	
	let(:request) do
		Protocol::HTTP::Request.new("http", "localhost", "GET", "/index", "HTTP/1.1", headers, nil)
	end
	
	def request_record
		console_capture.find{|record| record[:message].start_with?("->")}
	end
	
	def response_record
		console_capture.find{|record| record[:message].start_with?("<-")}
	end
	
	it "logs the request and response" do
		expect(request).to receive(:remote_address).and_return(Addrinfo.ip("127.0.0.1"))
		
		response = verbose.call(request)
		expect(response.read).to be == "ok"
		
		expect(request_record).to have_keys(
			severity: be == :info,
			message: be == "-> GET /index",
		)
		
		expect(response_record).to have_keys(
			severity: be == :info,
			message: be == "<- GET /index",
			status: be == 200,
		)
	end
	
	it "redacts sensitive request headers" do
		expect(request).to receive(:remote_address).and_return(Addrinfo.ip("127.0.0.1"))
		
		verbose.call(request).read
		
		logged_headers = request_record[:headers]
		
		expect(logged_headers).to have_keys(
			"accept" => be == ["*/*"],
			"authorization" => be == "[REDACTED]",
			"proxy-authorization" => be == "[REDACTED]",
			"cookie" => be == "[REDACTED]",
		)
		
		expect(logged_headers.inspect).not.to be(:include?, "secret")
		expect(logged_headers.inspect).not.to be(:include?, "cHJveHk6aHVudGVyMg==")
		expect(logged_headers.inspect).not.to be(:include?, "abc")
	end
	
	it "redacts sensitive response headers" do
		expect(request).to receive(:remote_address).and_return(Addrinfo.ip("127.0.0.1"))
		
		verbose.call(request).read
		
		logged_headers = response_record[:headers]
		
		expect(logged_headers).to have_keys(
			"content-type" => be == "text/plain",
			"set-cookie" => be == "[REDACTED]",
		)
		
		expect(logged_headers.inspect).not.to be(:include?, "xyz")
	end
	
	it "does not modify the original headers" do
		expect(request).to receive(:remote_address).and_return(Addrinfo.ip("127.0.0.1"))
		
		response = verbose.call(request)
		response.read
		
		expect(request.headers["authorization"]).to be == "Bearer secret"
		expect(request.headers["cookie"]).to be == ["session=abc"]
		expect(response.headers["set-cookie"]).to be == ["session=xyz"]
	end
	
	with "#redacted_headers" do
		it "redacts every value of a multi-valued header" do
			headers = Protocol::HTTP::Headers.new([
				["set-cookie", "first=1"],
				["set-cookie", "second=2"],
			])
			
			redacted = verbose.redacted_headers(headers)
			
			expect(redacted).to be == {"set-cookie" => "[REDACTED]"}
		end
		
		it "preserves headers which are not sensitive" do
			headers = Protocol::HTTP::Headers["content-length" => "2", "accept" => "*/*"]
			
			redacted = verbose.redacted_headers(headers)
			
			expect(redacted).to be == {"content-length" => "2", "accept" => ["*/*"]}
		end
	end
end
