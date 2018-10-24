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
			self.description = "Run an HTTP server with one or more virtual hosts."
			
			options do
				option '--bind-insecure <address>', "Bind redirection to the given hostname/address", default: "http://localhost"
				option '--bind-secure <address>', "Bind proxy to the given hostname/address", default: "https://localhost"
				
				option '--self-signed', "Use self-signed SSL", default: false
			end
			
			many :sites
			
			CONFIG_RU = "config.ru"
			
			def load_app(path, verbose)
				config = File.join(path, CONFIG_RU)
				
				rack_app, options = Rack::Builder.parse_file(config)
				
				return Server.middleware(rack_app, verbose: verbose), options
			end
			
			def client
				Async::HTTP::Client.new(client_endpoint)
			end
			
			def run(verbose = false)
				hosts = Falcon::Hosts.new
				root = Dir.pwd
				
				sites.each do |path|
					name = File.basename(path)
					
					hosts.add(name) do |host|
						host.app_root = File.expand_path(path, root)
						
						if @options[:self_signed]
							host.self_signed!(name)
						else
							host.ssl_certificate_path = File.join(path, "ssl", "fullchain.pem")
							host.ssl_key_path = File.join(path, "ssl", "privkey.pem")
						end
					end
				end
				
				controller = Async::Container::Controller.new
				
				hosts.each do |name, host|
					if container = host.start
						controller << container
					end
				end
				
				controller << Async::Container::Forked.new do |task|
					proxy = hosts.proxy
					secure_endpoint = Async::HTTP::URLEndpoint.parse(@options[:bind_secure], ssl_context: hosts.ssl_context)
					
					Process.setproctitle("Falcon Proxy")
					
					proxy_server = Falcon::Server.new(proxy, secure_endpoint)
					
					proxy_server.run
				end
				
				controller << Async::Container::Forked.new do |task|
					redirection = hosts.redirection
					insecure_endpoint = Async::HTTP::URLEndpoint.parse(@options[:bind_insecure])
					
					Process.setproctitle("Falcon Redirector")
					
					redirection_server = Falcon::Server.new(redirection, insecure_endpoint)
					
					redirection_server.run
				end
				
				Process.setproctitle("Falcon Controller")
				
				return controller
			end
			
			def invoke(parent)
				container = run(parent.verbose?)
				
				container.wait
			end
		end
	end
end
