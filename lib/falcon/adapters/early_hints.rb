# frozen_string_literal: true

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

require 'protocol/http/middleware'

module Falcon
	module Adapters
		# Provide an interface for advising the client to preload related resources.
		class EarlyHints
			PRELOAD = /<(?<path>.*?)>;.*?rel=preload/
			
			# Initialize the early hints interface.
			#
			# @parameter request [Protocol::HTTP::Request]
			def initialize(request)
				@request = request
			end
			
			# Advise the request that the specified path should be preloaded.
			# @parameter path [String]
			# @parameter preload [Boolean] whether the client should preload the resource.
			def push(path, preload: true, **options)
				@request.push(path)
			end
			
			# Extract link headers and invoke {push}.
			def call(headers)
				headers.each do |key, value|
					if key.casecmp("link").zero? and match = PRELOAD.match(value)
						@request.push(match[:path])
					else
						Async.logger.warn(@request) {"Unsure how to handle early hints header: #{key}"}
					end
				end
			end
		end
	end
end
