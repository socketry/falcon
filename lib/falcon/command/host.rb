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

require_relative '../controller/host'
require_relative '../configuration'

require 'samovar'

module Falcon
	module Command
		class Host < Samovar::Command
			self.description = "Host the specified applications."
			
			many :paths, "Service configuration paths.", default: ["falcon.rb"]
			
			def container_class
				Async::Container.best_container_class
			end
			
			def configuration(verbose = false)
				configuration = Configuration.new(verbose)
				
				@paths.each do |path|
					path = File.expand_path(path)
					configuration.load_file(path)
				end
				
				return configuration
			end
			
			def controller
				Controller::Host.new(self)
			end
			
			def call
				Async.logger.info(self) do |buffer|
					buffer.puts "Falcon Host v#{VERSION} taking flight!"
					buffer.puts "- Configuration: #{@paths.join(', ')}"
					buffer.puts "- To terminate: Ctrl-C or kill #{Process.pid}"
					buffer.puts "- To reload all sites: kill -HUP #{Process.pid}"
				end
				
				self.controller.run
			end
		end
	end
end
