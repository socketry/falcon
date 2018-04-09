# Copyright, 2017, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

require 'async/http/server'

module Falcon
	class Input
		def initialize(body)
			@body = body
			@chunks = []
			
			@buffer = nil
			@closed = false
		end
		
		def each(&block)
			while @index < @chunks.count
				chunk = @chunks[@index]
				@index += 1
				yield chunk
			end
			
			@body.each do |chunk|
				@chunks << chunk
				yield chunk
			end
			
			@closed = true
		end
		
		def rewind
			@index = 0
			@closed = false
		end
		
		def read(length = nil, buffer = nil)
			unless @buffer
				self.each do |chunk|
					@buffer = chunk
					break
				end
			end
			
			if @buffer
				if length and @buffer.bytesize < length
					return @buffer.slice!(0, length)
				else
					buffer = @buffer
					@buffer = nil
					return buffer
				end
			end
		end
		
		def eof?
			@closed and @buffer.nil?
		end
		
		def gets
			read
		end
		
		def close
			@body.close
		end
	end
end
