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

require_relative 'service'

module Falcon
	class Application < Service
		def initialize(environment)
			super
			
			@bound_endpoint = nil
		end
		
		def name
			"Falcon Host for #{self.authority}"
		end
		
		def authority
			@evaluator.authority
		end
		
		def endpoint
			@evaluator.endpoint
		end
		
		def ssl_context
			@evaluator.ssl_context
		end
		
		def root
			@evaluator.root
		end
		
		def middleware
			@evaluator.middleware
		end
		
		def protocol
			@evaluator.protocol
		end
		
		def scheme
			@evaluator.scheme
		end
		
		def endpoint
			@evaluator.endpoint
		end
		
		def to_s
			"\#<#{self.class} #{@evaluator.authority}>"
		end
		
		def start
			Async.logger.info(self) {"Binding to #{self.endpoint}..."}
			
			@bound_endpoint = Async::Reactor.run do
				Async::IO::SharedEndpoint.bound(self.endpoint)
			end.wait
		end
		
		def setup(container)
			container.run(name: self.name, restart: true) do |task, instance|
				Async.logger.info(self) {"Starting application server, binding to #{@bound_endpoint}..."}
				
				server = Server.new(self.middleware, @bound_endpoint, self.protocol, self.scheme)
				
				server.run
				
				task.children.each(&:wait)
			end
		end
		
		def stop
			@bound_endpoint&.close
			@bound_endpoint = nil
		end
	end
end
