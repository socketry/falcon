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
			Protocol::HTTP::Response[200, {"content-type" => "text/plain", "set-cookie" => "session=s3cr3t-response-cookie"}, ["ok"]]
		end
	end
	
	let(:verbose) {subject.new(app)}
	
	let(:headers) do
		Protocol::HTTP::Headers[
			"accept" => "*/*",
			"authorization" => "Bearer s3cr3t-bearer-token",
			"proxy-authorization" => "Basic cHJveHk6aHVudGVyMg==",
			"cookie" => "session=s3cr3t-request-cookie",
			"x-api-key" => "s3cr3t-api-key",
		]
	end
	
	# Server requests expose the client address, which the middleware logs:
	let(:request_class) do
		Class.new(Protocol::HTTP::Request) do
			def remote_address
				Addrinfo.ip("127.0.0.1")
			end
		end
	end
	
	let(:request) do
		request_class.new("http", "localhost", "GET", "/index", "HTTP/1.1", headers, nil)
	end
	
	def request_record
		console_capture.find{|record| record[:message].start_with?("->")}
	end
	
	def response_record
		console_capture.find{|record| record[:message].start_with?("<-")}
	end
	
	# Everything that would be written to a log sink. The captured record also retains the request object itself as `:subject`, but the console outputs only ever write its class name, so it is excluded here.
	def logged(record)
		record.except(:subject).inspect
	end
	
	it "logs the request and response" do
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
		verbose.call(request).read
		
		record = request_record
		
		expect(record[:headers]).to have_keys(
			"accept" => be == ["*/*"],
			"authorization" => be == "[REDACTED]",
			"proxy-authorization" => be == "[REDACTED]",
			"cookie" => be == "[REDACTED]",
			"x-api-key" => be == "[REDACTED]",
		)
		
		expect(logged(record)).not.to be(:include?, "s3cr3t-bearer-token")
		expect(logged(record)).not.to be(:include?, "cHJveHk6aHVudGVyMg==")
		expect(logged(record)).not.to be(:include?, "s3cr3t-request-cookie")
		expect(logged(record)).not.to be(:include?, "s3cr3t-api-key")
	end
	
	it "redacts sensitive response headers" do
		verbose.call(request).read
		
		record = response_record
		
		expect(record[:headers]).to have_keys(
			"content-type" => be == "text/plain",
			"set-cookie" => be == "[REDACTED]",
		)
		
		expect(logged(record)).not.to be(:include?, "s3cr3t-response-cookie")
	end
	
	it "does not modify the original headers" do
		response = verbose.call(request)
		response.read
		
		expect(request.headers["authorization"]).to be == "Bearer s3cr3t-bearer-token"
		expect(request.headers["cookie"]).to be == ["session=s3cr3t-request-cookie"]
		expect(request.headers["x-api-key"]).to be == ["s3cr3t-api-key"]
		expect(response.headers["set-cookie"]).to be == ["session=s3cr3t-response-cookie"]
	end
	
	with "custom redacted headers" do
		let(:verbose) {subject.new(app, redacted_headers: ["x-custom-secret"])}
		
		let(:headers) do
			Protocol::HTTP::Headers[
				"authorization" => "Bearer visible-token",
				"x-custom-secret" => "s3cr3t-custom-value",
			]
		end
		
		it "redacts only the configured headers" do
			verbose.call(request).read
			
			record = request_record
			
			expect(record[:headers]).to have_keys(
				"authorization" => be == "Bearer visible-token",
				"x-custom-secret" => be == "[REDACTED]",
			)
			
			expect(logged(record)).not.to be(:include?, "s3cr3t-custom-value")
		end
	end
	
	with "REDACTED_HEADERS" do
		it "is frozen" do
			expect(subject::REDACTED_HEADERS).to be(:frozen?)
		end
		
		it "includes standard credential and common API token headers" do
			expect(subject::REDACTED_HEADERS).to be(:superset?, Set[
				"authorization", "proxy-authorization", "cookie", "set-cookie",
				"x-api-key", "x-auth-token", "x-access-token", "x-csrf-token", "x-xsrf-token",
				"x-amz-security-token", "x-forwarded-authorization", "private-token",
			])
		end
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
		
		it "does not modify the memoised header index" do
			headers = Protocol::HTTP::Headers["authorization" => "Bearer s3cr3t-bearer-token"]
			index = headers.to_h
			
			redacted = verbose.redacted_headers(headers)
			
			expect(redacted).not.to be_equal(index)
			expect(index["authorization"]).to be == "Bearer s3cr3t-bearer-token"
			expect(headers.to_h["authorization"]).to be == "Bearer s3cr3t-bearer-token"
		end
	end
end
