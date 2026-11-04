# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2026, by Samuel Williams.

require "console"
require "set"
require "async/http/statistics"
require "protocol/http/middleware"

module Falcon
	module Middleware
		# A HTTP middleware for logging requests and responses.
		class Verbose < Protocol::HTTP::Middleware
			# Headers whose values carry credentials or session tokens, and must never be written to logs verbatim.
			#
			# This is an explicit list of standard and commonly used custom header names, rather than a pattern, so that the behaviour is predictable. Pass `redacted_headers:` to {initialize} to use a different list.
			REDACTED_HEADERS = Set[
				# Standard credential and session headers:
				"authorization",
				"proxy-authorization",
				"cookie",
				"set-cookie",
			
				# Common custom API token and CSRF headers:
				"x-api-key",
				"x-auth-token",
				"x-access-token",
				"x-csrf-token",
				"x-xsrf-token",
				"x-amz-security-token",
				"x-forwarded-authorization",
				"private-token",
			].freeze
			
			# The placeholder written in place of a redacted header value.
			REDACTED = "[REDACTED]"
			
			# Initialize the verbose middleware.
			# @parameter app [Protocol::HTTP::Middleware] The middleware to wrap.
			# @parameter logger [Console::Logger] The logger to use.
			# @parameter redacted_headers [Enumerable(String)] Lower-case header names whose values are replaced by {REDACTED} when logged.
			def initialize(app, logger = Console, redacted_headers: REDACTED_HEADERS)
				super(app)
				
				@logger = logger
				@redacted_headers = redacted_headers
			end
			
			# Convert the headers to a hash suitable for logging, with sensitive values redacted.
			# The header names are preserved so that it is still possible to see which headers were present.
			# @parameter headers [Protocol::HTTP::Headers] The headers to redact.
			# @returns [Hash] The headers as a hash, with sensitive values replaced by {REDACTED}.
			def redacted_headers(headers)
				# `Headers#to_h` returns the memoised internal index, so we must copy it rather than modify it in place:
				copy = headers.to_h.dup
				
				@redacted_headers.each do |name|
					copy[name] = REDACTED if copy.key?(name)
				end
				
				return copy
			end
			
			# Log details of the incoming request.
			def annotate(request)
				task = Async::Task.current
				address = request.remote_address
				
				@logger.info(request, "-> #{request.method} #{request.path}", headers: redacted_headers(request.headers), address: address.inspect)
				
				task.annotate("#{request.method} #{request.path} from #{address.inspect}")
			end
			
			# Log details of the incoming request using {annotate} and wrap the response to log response details too.
			def call(request)
				annotate(request)
				
				statistics = Async::HTTP::Statistics.start
				
				response = super
				
				statistics.wrap(response) do |body, error|
					@logger.info(request, "<- #{request.method} #{request.path}", headers: redacted_headers(response.headers), status: response.status, body: body.inspect, error: error)
				end
				
				return response
			end
		end
	end
end
