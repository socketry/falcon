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

module Falcon
	class Verbose
		def initialize(app, logger = Async.logger)
			@app = app
			@logger = logger
		end
		
		def annotate(env, task = Async::Task.current)
			request_method = env['REQUEST_METHOD']
			request_path = env['PATH_INFO']
			remote_address = env['REMOTE_ADDR']
			
			task.annotate("#{request_method} #{request_path} for #{remote_address}")
		end
		
		def log(start_time, env, response, error)
			duration = Time.now - start_time
			
			request_method = env['REQUEST_METHOD']
			request_path = env['PATH_INFO']
			
			if response
				status, headers, body = response
				@logger.info "#{request_method} #{request_path} -> #{status}; Content length #{headers.fetch('Content-Length', '-')} bytes; took #{duration} seconds"
			else
				@logger.info "#{request_method} #{request_path} -> #{error}; took #{duration} seconds"
			end
		end
		
		def call(env)
			start_time = Time.now
			
			annotate(env)
			
			response = @app.call(env)
		ensure
			log(start_time, env, response, $!)
		end
	end
end
