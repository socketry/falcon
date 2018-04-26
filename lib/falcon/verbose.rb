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
	class Verbose < Async::HTTP::Middleware
		def initialize(app, logger = Async.logger)
			super(app)
			
			@logger = logger
		end
		
		def annotate(request, peer: nil, address: nil)
			task = Async::Task.current
			
			@logger.debug(request.authority) {"#{request.method} #{request.path} #{request.version} from #{address.inspect}"}
			@logger.debug(request.authority) {request.headers.inspect}
			
			task.annotate("#{request.method} #{request.path} from #{address.inspect}")
		end
		
		def call(request, **options)
			annotate(request, **options)
			
			statistics = Async::HTTP::Statistics.start
			
			response = super
			
			statistics.wrap(response) do |statistics, error|
				@logger.info(request.authority) {"#{request.method} #{request.path} #{request.version} -> #{response.status}; #{statistics.inspect}"}
				# @logger.info response.headers.inspect
				@logger.error(request.authority) {"#{error.class}: #{error.message}"} if error
			end
			
			return response
		end
	end
end
