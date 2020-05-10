# frozen_string_literal: true

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

require 'async/io/unix_endpoint'

module Falcon
	# An endpoint suitable for proxing requests, typically via a unix pipe.
	class ProxyEndpoint < Async::IO::Endpoint
		# Initialize the proxy endpoint.
		# @parameter endpoint [Async::IO::Endpoint] The endpoint which will be used for connecting/binding.
		def initialize(endpoint, **options)
			super(**options)
			
			@endpoint = endpoint
		end
		
		def to_s
			"\#<#{self.class} endpoint=#{@endpoint}>"
		end
		
		# The actual endpoint for I/O.
		# @attribute [Async::IO::Endpoint]
		attr :endpoint
		
		# The protocol to use for this connection.
		# @returns [Async::HTTP::Protocol] A specific protocol, e.g. {Async::HTTP::P}
		def protocol
			@options[:protocol]
		end
		
		# The scheme to use for this endpoint.
		# e.g. `"http"`.
		# @returns [String]
		def scheme
			@options[:scheme]
		end
		
		# The authority to use for this endpoint.
		# e.g. `"myapp.com"`.
		# @returns [String]
		def authority
			@options[:authority]
		end
		
		# Connect to the endpoint.
		def connect(&block)
			@endpoint.connect(&block)
		end
		
		# Bind to the endpoint.
		def bind(&block)
			@endpoint.bind(&block)
		end
		
		# Enumerate the endpoint.
		# If the endpoint has multiple underlying endpoints, this will enumerate them individually.
		# @yields {|endpoint| ...}
		# 	@parameter endpoint [ProxyEndpoint]
		def each
			return to_enum unless block_given?
			
			@endpoint.each do |endpoint|
				yield self.class.new(endpoint, **@options)
			end
		end
		
		# Create a proxy unix endpoint with the specific path.
		# @returns [ProxyEndpoint]
		def self.unix(path, **options)
			self.new(::Async::IO::Endpoint.unix(path), **options)
		end
	end
end
