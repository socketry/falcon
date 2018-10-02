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
require 'async/http/body/file'

module Falcon
	module Adapters
		# Wraps the rack response body.
		# The Body must respond to each and must only yield String values. The Body itself should not be an instance of String, as this will break in Ruby 1.9. If the Body responds to close, it will be called after iteration. If the body is replaced by a middleware after action, the original body must be closed first, if it responds to close. If the Body responds to to_path, it must return a String identifying the location of a file whose contents are identical to that produced by calling each; this may be used by the server as an alternative, possibly more efficient way to transport the response. The Body commonly is an Array of Strings, the application instance itself, or a File-like object.
		class Output < Async::HTTP::Body::Readable
			CONTENT_LENGTH = 'content-length'.freeze
			
			# Wraps an array into a buffered body.
			def self.wrap(status, headers, body)
				# In no circumstance do we want this header propagating out:
				if content_length = headers.delete(CONTENT_LENGTH)
					# We don't really trust the user to provide the right length to the transport.
					content_length = Integer(content_length)
				end
				
				if body.is_a?(Async::HTTP::Body::Readable)
					return body
				elsif status == 200 and body.respond_to?(:to_path)
					# Don't mangle partial responsese (206)
					return Async::HTTP::Body::File.open(body.to_path)
				else
					return self.new(headers, body, content_length)
				end
			end
			
			def initialize(headers, body, length)
				@length = length
				@body = body
				
				# An enumerator over the rack response body:
				@chunks = body.to_enum(:each)
			end
			
			# The rack response body.
			attr :body
			
			# The content length of the rack response body.
			attr :length
			
			def empty?
				@length == 0 or (@body.respond_to?(:empty?) and @body.empty?)
			end
			
			def close(error = nil)
				if @body and @body.respond_to?(:close)
					@body.close
					@body = nil
				end
				
				@chunks = nil
				
				super
			end
			
			def read
				if @chunks
					return @chunks.next
				end
			rescue StopIteration
				nil
			end
			
			def inspect
				"\#<#{self.class} length=#{@length.inspect} body=#{@body.class}>"
			end
		end
	end
end
