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

require 'async/http/url_endpoint'

module Falcon
	class Endpoint < Async::HTTP::URLEndpoint
		def ssl_context
			@options[:ssl_context] || build_ssl_context
		end
		
		def build_ssl_context(hostname = self.hostname)
			authority = Localhost::Authority.fetch(hostname)
			
			authority.server_context.tap do |context|
				context.alpn_select_cb = lambda do |protocols|
					if protocols.include? "h2"
						return "h2"
					elsif protocols.include? "http/1.1"
						return "http/1.1"
					elsif protocols.include? "http/1.0"
						return "http/1.0"
					else
						return nil
					end
				end
				
				context.session_id_context = "falcon"
				context.set_params
				context.freeze
			end
		end
	end
end
