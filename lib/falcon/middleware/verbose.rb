# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2023, by Samuel Williams.

require "console"
require "async/http/statistics"

module Falcon
	module Middleware
		# A HTTP middleware for logging requests and responses.
		class Verbose < Protocol::HTTP::Middleware
			# Initialize the verbose middleware.
			# @parameter app [Protocol::HTTP::Middleware] The middleware to wrap.
			# @parameter logger [Console::Logger] The logger to use.
			def initialize(app, logger = Console.logger)
				super(app)
				
				@logger = logger
			end
			
			# Log details of the incoming request.
			def annotate(request)
				task = Async::Task.current
				address = request.remote_address
				
				@logger.info(request) {"Headers: #{request.headers.to_h} from #{address.inspect}"}
				
				task.annotate("#{request.method} #{request.path} from #{address.inspect}")
			end
			
			# Log details of the incoming request using {annotate} and wrap the response to log response details too.
			def call(request)
				annotate(request)
				
				statistics = Async::HTTP::Statistics.start
				
				response = super
				
				statistics.wrap(response) do |statistics, error|
					@logger.info(request) {"Responding with: #{response.status} #{response.headers.to_h}; #{statistics.inspect}"}
					
					@logger.error(request) {"#{error.class}: #{error.message}"} if error
				end
				
				return response
			end
		end
	end
end
