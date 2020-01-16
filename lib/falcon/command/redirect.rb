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

require_relative '../container/redirect'

require 'samovar'

module Falcon
	module Command
		class Redirect < Samovar::Command
			self.description = "Redirect from insecure HTTP to secure HTTP."
			
			options do
				option '--bind <address>', "Bind to the given hostname/address", default: "http://[::]:80"
				option '--redirect <address>', "Redirect using this address as a template.", default: "https://[::]:443"
			end
			
			many :paths
			
			def controller
				Container::Redirect.new(self)
			end
			
			def container_class
				Async::Container.best_container_class
			end
			
			def container_options
				{}
			end
			
			def call
				Async.logger.info(self) do |buffer|
					buffer.puts "Falcon Redirect v#{VERSION} taking flight!"
					buffer.puts "- Binding to: #{@options[:bind]}"
					buffer.puts "- To terminate: Ctrl-C or kill #{Process.pid}"
					buffer.puts "- To reload: kill -HUP #{Process.pid}"
				end
				
				self.controller.run
			end
			
			def endpoint(**options)
				Async::HTTP::Endpoint.parse(@options[:bind], **options)
			end
			
			def redirect_endpoint(**options)
				Async::HTTP::Endpoint.parse(@options[:redirect], **options)
			end
		end
	end
end
