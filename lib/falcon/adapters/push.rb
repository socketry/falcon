# Copyright, 2019, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

require 'async/http/middleware'

module Falcon
	module Adapters
		# Interprets link headers to implement server push.
		# https://tools.ietf.org/html/rfc8288
		class Push < Async::HTTP::Middleware
			PRELOAD = /<(?<path>.*?)>;.*?rel=preload/
			
			def self.early_hints(headers)
				headers.each do |key, value|
					if key.casecmp("link").zero? and match = PRELOAD.match(value)
						yield match[:path]
					else
						Async.logger.warn(request) {"Unsure how to handle early hints header: #{key}"}
					end
				end
			end
			
			def call(request)
				response = super
				
				Async.logger.debug(self) {response}
				
				if request.push?
					Async.logger.debug(self) {response.headers['link']}
					
					response.headers['link']&.each do |link|
						if match = link.match(PRELOAD)
							request.push(match[:path])
						end
					end
				end
				
				return response
			end
		end
	end
end
