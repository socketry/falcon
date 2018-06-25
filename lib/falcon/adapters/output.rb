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

require 'async/http/body/readable'

module Falcon
	module Adapters
		class Output < Async::HTTP::Body::Readable
			# Wraps an array into a buffered body.
			def self.wrap(headers, body)
				if body.is_a? Async::HTTP::Body::Readable
					return body
				elsif body.respond_to? :to_path
					return Async::HTTP::Body::File.new(body.to_path)
				elsif body.is_a? Array
					return Async::HTTP::Body::Buffered.new(body)
				else
					return self.new(headers, body)
				end
			end
			
			def initialize(headers, body)
				@bytesize = headers['content-length']
				@body = body
				@chunks = body.each
			end
			
			attr :bytesize
			
			def empty?
				@bytesize == 0
			end
			
			def read
				@chunks.next
			rescue StopIteration
				nil
			end
			
			def inspect
				"\#<#{self.class} #{@body}>"
			end
		end
	end
end
