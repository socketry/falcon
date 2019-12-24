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

require_relative '../../server'
require_relative '../../endpoint'
require_relative '../../configuration'
require_relative '../../hosts'
require_relative '../../services'

require 'async/container'
require 'async/container/controller'

require 'async/io/host_endpoint'
require 'async/io/shared_endpoint'
require 'async/io/ssl_endpoint'

require 'samovar'

require 'rack/builder'
require 'rack/server'

module Falcon
	module Command
		class Host < Samovar::Command
			self.description = "Run a specific virtual host."
			
			one :path, "A path specified if running from a script."
			
			def assume_privileges(path)
				stat = File.stat(path)
				
				Process::GID.change_privilege(stat.gid)
				Process::UID.change_privilege(stat.uid)
			end
			
			def run(container, verbose = false)
				configuration = Configuration.new(verbose)
				configuration.load_file(@path)
				
				Async.logger.info(self) {"Starting services described by #{@path}..."}
				
				assume_privileges(@path)
				
				hosts = Hosts.new(configuration)
				hosts.each do |host|
					host.run(container)
				end
				
				services = Services.new(configuration)
				services.each do |service|
					service.run(container)
				end
				
				return container
			end
			
			def call(container = Async::Container.new)
				container = run(container, parent&.verbose?)
				
				Signal.trap(:USR2) do
					replacement = run(container.class.new, parent&.verbose?)
					
					container.stop
					
					container = replacement
				end
				
				container.wait(true)
			end
		end
	end
end
