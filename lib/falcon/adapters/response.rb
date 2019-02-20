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

require_relative 'output'
require_relative '../version'
require_relative '../proxy'

require 'time'

module Falcon
	module Adapters
		class Response < Async::HTTP::Response
			IGNORE_HEADERS = Set.new(Proxy::HOP_HEADERS)
			
			# Append a list of newline encoded headers.
			def self.wrap_headers(fields)
				headers = ::HTTP::Protocol::Headers.new
				
				fields.each do |key, value|
					next if key.start_with? 'rack.'
					
					# This is a quick fix, but perhaps it should be part of the protocol, because it IS valid for HTTP/1.
					key = key.downcase
					
					if IGNORE_HEADERS.include? key
						Async.logger.warn("Ignoring protocol-level header: #{key}: #{value}!")
					else
						value.to_s.split("\n").each do |part|
							headers.add(key, part)
						end
					end
				end
				
				return headers
			end
			
			def self.wrap(status, headers, body)
				headers = wrap_headers(headers)
				
				# https://tools.ietf.org/html/rfc7231#section-7.4.2
				# headers.add('server', "falcon/#{Falcon::VERSION}")
				
				# https://tools.ietf.org/html/rfc7231#section-7.1.1.2
				# headers.add('date', Time.now.httpdate)
				
				body = Output.wrap(status, headers, body)
				
				return self.new(status, headers, body)
			end
			
			def initialize(status, headers, body)
				super(nil, status, nil, headers, body)
			end
		end
	end
end
