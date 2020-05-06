# frozen_string_literal: true

# Copyright, 2018, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'async/logger'
require 'async/http/statistics'

module Falcon
	module Middleware
		# A HTTP middleware for logging requests and responses.
		class Verbose < Protocol::HTTP::Middleware
			# Initialize the verbose middleware.
			# @param app [Protocol::HTTP::Middleware] The middleware to wrap.
			# @param logger [Console::Logger] The logger to use.
			def initialize(app, logger = Async.logger)
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
