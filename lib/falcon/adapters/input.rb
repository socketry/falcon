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
		# The input stream is an IO-like object which contains the raw HTTP POST data. When applicable, its external encoding must be “ASCII-8BIT” and it must be opened in binary mode, for Ruby 1.9 compatibility. The input stream must respond to gets, each, read and rewind.
		class Input
			def initialize(body)
				# The streaming input body.
				@body = body
				
				# A buffer of chunks, including an index to the current chunk for `#read_next`.
				@chunks = []
				@index = 0
				
				# The current buffer, which is extended by calling `#fill_buffer`.
				@buffer = Async::IO::BinaryString.new
				@finished = @body.nil?
			end
			
			attr :body
			
			attr :chunks
			attr :index
			
			# each must be called without arguments and only yield Strings.
			def each(&block)
				return to_enum unless block_given?
				
				while chunk = read_next
					yield chunk
				end
				
				@closed = true
			end
			
			# rewind must be called without arguments. It rewinds the input stream back to the beginning. It must not raise Errno::ESPIPE: that is, it may not be a pipe or a socket. Therefore, handler developers must buffer the input data into some rewindable object if the underlying input stream is not rewindable.
			def rewind
				@index = 0
				@finished = false
				@buffer.clear
			end
			
			# Clears all cached chunks.
			def clear
				@chunks.clear
				
				# The currently unread portion of the buffer becomes the first chunk.
				unless @buffer.empty?
					@chunks << @buffer.dup
				end
				
				@index = 0
			end
			
			# read behaves like IO#read. Its signature is read([length, [buffer]]). If given, length must be a non-negative Integer (>= 0) or nil, and buffer must be a String and may not be nil. If length is given and not nil, then this method reads at most length bytes from the input stream. If length is not given or nil, then this method reads all data until EOF. When EOF is reached, this method returns nil if length is given and not nil, or “” if length is not given or is nil. If buffer is given, then the read data will be placed into buffer instead of a newly created String object.
			# @param length [Integer] the amount of data to read
			# @param buffer [String] the buffer which will receive the data
			# @return a buffer containing the data
			def read(length = nil, buffer = nil)
				if length
					fill_buffer(length) if @buffer.bytesize <= length
					
					chunk = @buffer.slice!(0, length)
					
					if buffer
						# TODO https://bugs.ruby-lang.org/issues/14745
						buffer.replace(chunk)
					else
						buffer = chunk
					end
					
					if buffer.empty? and length > 0
						return nil
					else
						return buffer
					end
				else
					buffer ||= Async::IO::BinaryString.new
					
					buffer.replace(@buffer)
					@buffer.clear
					
					while chunk = read_next
						buffer << chunk
					end
					
					return buffer
				end
			end
			
			def eof?
				@finished and @buffer.empty?
			end
			
			# gets must be called without arguments and return a string, or nil on EOF.
			# @return [String, nil] The next chunk from the body.
			def gets
				if @buffer.empty?
					read_next
				else
					buffer = @buffer.dup
					@buffer.clear
					
					return buffer
				end
			end
			
			# close must never be called on the input stream. huh?
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
