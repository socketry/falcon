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

require 'async/container/controller'

module Falcon
	module Controller
		class Virtual < Async::Container::Controller
			def initialize(command, **options)
				@command = command
				
				super(**options)
				
				trap(SIGHUP, &self.method(:reload))
			end
			
			def assume_privileges(path)
				stat = File.stat(path)
				
				Process::GID.change_privilege(stat.gid)
				Process::UID.change_privilege(stat.uid)
				
				home = Etc.getpwuid(stat.uid).dir
				
				return {
					'HOME' => home,
				}
			end
			
			def spawn(path, container, **options)
				container.spawn(name: "Falcon Application", restart: true, key: path) do |instance|
					env = assume_privileges(path)
					
					instance.exec(env,
						"bundle", "exec", "--keep-file-descriptors",
						path, ready: false, **options)
				end
			end
			
			def falcon_path
				File.expand_path("../../../bin/falcon", __dir__)
			end
			
			def setup(container)
				if proxy = container[:proxy]
					proxy.kill(:HUP)
				end
				
				if redirect = container[:redirect]
					redirect.kill(:HUP)
				end
				
				container.reload do
					@command.resolved_paths do |path|
						path = File.expand_path(path)
						root = File.dirname(path)
						
						spawn(path, container, chdir: root)
					end
					
					container.spawn(name: "Falcon Redirector", restart: true, key: :redirect) do |instance|
						instance.exec(falcon_path, "redirect", "--bind", @command.bind_insecure, "--redirect", @command.bind_secure, *@command.paths, ready: false)
					end
					
					container.spawn(name: "Falcon Proxy", restart: true, key: :proxy) do |instance|
						instance.exec(falcon_path, "proxy", "--bind", @command.bind_secure, *@command.paths, ready: false)
					end
				end
			end
		end
	end
end
