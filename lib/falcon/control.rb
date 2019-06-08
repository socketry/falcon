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

require 'async/io/endpoint'

require_relative 'proxy'
require_relative 'redirection'

require 'async/container'
require 'async/container/controller'
require 'async/http/endpoint'

module Falcon
	class Control
		def initialize(environment)
			@environment = environment.flatten
			@evaluator = @environment.evaluator
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
		
		def bound_endpoint
			@evaluator.bound_endpoint
		end
		
		def to_s
			"\#<#{self.class} #{@evaluator.authority}>"
		end
		
		def assume_privileges(path)
			stat = File.stat(path)
			
			Process::GID.change_privilege(stat.gid)
			Process::UID.change_privilege(stat.uid)
		end
		
		def spawn(container)
			container.spawn(name: self.name, restart: true) do |instance|
				path = File.join(self.root, "falcon.rb")
				
				assume_privileges(path)
				
				instance.exec("bundle", "exec", path)
			end
		end
		
		def run(container)
			if @environment.include?(:server)
				container.run(name: self.name, count: 1, restart: true) do |task, instance|
					Async.logger.info(self) {"Starting host controller..."}
					
					server = @evaluator.server
					
					server.run
					
					task.children.each(&:wait)
				end
			end
		end
	end
end
