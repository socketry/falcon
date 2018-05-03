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

require 'async/http/client'

module Falcon
	module BadRequest
		def self.call(request, *)
			return Async::HTTP::Response[400, {}, []]
		end
		
		def self.close
		end
	end
	
	class Proxy < Async::HTTP::Middleware
		X_FORWARDED_FOR = 'x-forwarded-for'.freeze
		
		def initialize(app, hosts)
			super(app)
			
			@server_context = nil
			
			@hosts = hosts
			@clients = {}
			
			@count = 0
		end
		
		attr :count
		
		def close
			@clients.each_value(&:close)
			
			super
		end
		
		def connect(endpoint)
			@clients[endpoint] ||= Async::HTTP::Client.new(endpoint)
		end
		
		def lookup(request)
			# Trailing dot and port is ignored/normalized.
			if authority = request.authority.sub(/(\.)?(:\d+)?$/, '')
				return @hosts[authority]
			end
		end
		
		def call(request, peer: nil)
			if endpoint = lookup(request)
				@count += 1
				
				if peer and address = peer.remote_address and address.ip?
					if forwarded = request.headers[X_FORWARDED_FOR]
						forwarded = "#{forwarded}, #{address.ip_address}"
					else
						forwarded = address.ip_address
					end
					
					request.headers[X_FORWARDED_FOR] = forwarded
				end
				
				client = connect(endpoint)
				
				client.call(request)
			else
				super
			end
		end
	end
end
