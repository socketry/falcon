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
require 'async/io/buffer'

module Falcon
	module Adapters
		# This is used for implementing partial hijack.
		class Hijack
			def self.for(env, block, socket = nil, task: Async::Task.current)
				input = socket || env[Rack::RACK_INPUT]
				output = Async::HTTP::Body::Writable.new
				
				stream = Hijack.new(input, output)
				
				task.async do
					begin
						block.call(stream)
					ensure
						output.close
					end
				end
				
				return output
			end
			
			def initialize(input, output)
				@input = input
				@output = output
			end
			
			def read(length = nil, buffer = nil)
				@input.read(length, buffer)
			end
			
			def read_nonblock(length, buffer = nil)
				@input.read(length, buffer)
			end
			
			def write(buffer)
				@output.write(buffer)
			end
			
			alias write_nonblock write
			
			def flush
			end
			
			def close
				@output.close
			end
			
			def close_read
				if @input.respond_to?(:close_read)
					@input.close_read
				else
					@input.close
				end
			end
			
			def close_write
				@output.close
			end
		end
	end
end
