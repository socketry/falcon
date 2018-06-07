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

require 'async/http/body'

module Falcon
	module Adapters
		class Input
			def initialize(body)
				@body = body
				@chunks = []
				
				@index = 0
				@buffer = Async::IO::BinaryString.new
				@finished = @body.nil?
			end
			
			def each(&block)
				return to_enum unless block_given?
				
				while chunk = read_next
					yield chunk
				end
				
				@closed = true
			end
			
			def rewind
				@index = 0
				@finished = false
				@buffer.clear
			end
			
			def read(length = nil, buffer = nil)
				buffer ||= Async::IO::BinaryString.new
				buffer.clear
				
				if length
					fill_buffer(length) if @buffer.bytesize <= length
					
					buffer << @buffer.slice!(0, length)
				else
					buffer << @buffer
					@buffer.clear
					
					while chunk = read_next
						buffer << chunk
					end
				end
				
				buffer unless length && length > 0 && buffer.empty?
			end
			
			def eof?
				@finished and @buffer.empty?
			end
			
			def gets
				read
			end
			
			def close
				@body.finish
			end
			
			private
			
			def read_next
				return nil if @finished
				
				chunk = nil
				
				if @index < @chunks.count
					chunk = @chunks[@index]
					@index += 1
				else
					if chunk = @body.read
						@chunks << chunk
						@index += 1
					end
				end
				
				@finished = true if chunk.nil?
				
				return chunk
			end
			
			def fill_buffer(length)
				while @buffer.bytesize < length and chunk = read_next
					@buffer << chunk
				end
			end
		end
	end
end
