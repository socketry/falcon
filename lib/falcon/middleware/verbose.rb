# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2026, by Samuel Williams.

require "console"
require "async/http/statistics"
require "protocol/http/middleware"

module Falcon
	module Middleware
		# A HTTP middleware for logging requests and responses.
		class Verbose < Protocol::HTTP::Middleware
			# Headers whose values carry credentials or session tokens, and must never be written to logs verbatim.
			REDACTED_HEADERS = ["authorization", "proxy-authorization", "cookie", "set-cookie"].freeze
			
			# The placeholder written in place of a redacted header value.
			REDACTED = "[REDACTED]"
			
			# Initialize the verbose middleware.
			# @parameter app [Protocol::HTTP::Middleware] The middleware to wrap.
			# @parameter logger [Console::Logger] The logger to use.
			def initialize(app, logger = Console)
				super(app)
				
				@logger = logger
			end
			
			# Convert the headers to a hash suitable for logging, with sensitive values redacted.
			# The header names are preserved so that it is still possible to see which headers were present.
			# @parameter headers [Protocol::HTTP::Headers] The headers to redact.
			# @returns [Hash] The headers as a hash, with sensitive values replaced by {REDACTED}.
			def redacted_headers(headers)
				# `Headers#to_h` returns the internal index, so we must not modify it in place:
				headers.to_h.to_h do |name, value|
					if REDACTED_HEADERS.include?(name)
						[name, REDACTED]
					else
						[name, value]
					end
				end
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
