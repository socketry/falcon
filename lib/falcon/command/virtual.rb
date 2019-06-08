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

require_relative '../server'
require_relative '../endpoint'
require_relative '../hosts'
require_relative '../configuration'

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
		class Virtual < Samovar::Command
			self.description = "Run one or more virtual hosts with a front-end proxy."
			
			options do
				option '--bind-insecure <address>', "Bind redirection to the given hostname/address", default: "http://[::]"
				option '--bind-secure <address>', "Bind proxy to the given hostname/address", default: "https://[::]"
			end
			
			many :paths
			
			def assume_privileges(path)
				stat = File.stat(path)
				
				Process::GID.change_privilege(stat.gid)
				Process::UID.change_privilege(stat.uid)
			end
			
			def spawn(path, container)
				container.spawn(name: self.name, restart: true) do |instance|
					assume_privileges(path)
					
					instance.exec("bundle", "exec", path)
				end
			end
			
			def run(verbose = false)
				configuration = Configuration.new(verbose)
				container = Async::Container.new
				
				@paths.each do |path|
					configuration.load_file(path)
					spawn(path, container)
				end
				
				hosts = Hosts.new(configuration)
				hosts.run(container, **@options)
				
				return container
			end
			
			def call
				container = run(parent.verbose?)
				
				container.wait
			end
			
			def insecure_endpoint
				Async::HTTP::Endpoint.parse(@options[:bind_insecure])
			end
			
			def secure_endpoint
				Async::HTTP::Endpoint.parse(@options[:bind_secure])
			end
		end
	end
end
