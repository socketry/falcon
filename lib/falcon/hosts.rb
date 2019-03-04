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
require 'async/http/url_endpoint'

module Falcon
	class Host
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
		
		def run(container)
			Async.logger.info(self) {"Starting server..."}
			
			if @environment.include?(:server)
				bound_endpoint = self.bound_endpoint
				
				container.run(count: 1, name: self.name) do |task, instance|
					if root = self.root
						Dir.chdir(root)
					end
					
					server = @evaluator.server
					
					server.run
					
					task.children.each(&:wait)
				end
			else
				pp "Could not run host: #{@environment.name} no server found"
			end
		end
	end
	
	class Hosts
		DEFAULT_ALPN_PROTOCOLS = ['h2', 'http/1.1'].freeze
		
		def initialize(configuration)
			@named = {}
			@server_context = nil
			@server_endpoint = nil
			
			configuration.each do |environment|
				add(Host.new(environment))
			end
		end
		
		def each(&block)
			@named.each(&block)
		end
		
		def endpoint
			@server_endpoint ||= Async::HTTP::URLEndpoint.parse(
				'https://[::]',
				ssl_context: self.ssl_context,
				reuse_address: true
			)
		end
		
		def ssl_context
			@server_context ||= OpenSSL::SSL::SSLContext.new.tap do |context|
				context.servername_cb = Proc.new do |socket, hostname|
					self.host_context(socket, hostname)
				end
				
				context.session_id_context = "falcon"
				context.alpn_protocols = DEFAULT_ALPN_PROTOCOLS
				context.set_params
				
				context.setup
			end
		end
		
		def host_context(socket, hostname)
			if host = @named[hostname]
				Async.logger.debug(self) {"Resolving #{hostname} -> #{host}"}
				
				socket.hostname = hostname
				
				return host.ssl_context
			else
				Async.logger.warn(self) {"Unable to resolve #{hostname}!"}
				
				return nil
			end
		end
		
		def add(host)
			@named[host.authority] = host
		end
		
		def proxy
			Proxy.new(Falcon::BadRequest, @named)
		end
		
		def redirection(secure_endpoint)
			Redirection.new(Falcon::BadRequest, @named, secure_endpoint)
		end
		
		def run(container = Async::Container::Forked.new, **options)
			@named.each do |name, host|
				host.run(container)
			end
			
			secure_endpoint = Async::HTTP::URLEndpoint.parse(options[:bind_secure], ssl_context: self.ssl_context)
			insecure_endpoint = Async::HTTP::URLEndpoint.parse(options[:bind_insecure])
			
			container.run(count: 1, name: "Falcon Proxy") do |task, instance|
				proxy = self.proxy
				
				proxy_server = Falcon::Server.new(proxy, secure_endpoint)
				
				proxy_server.run
			end
			
			container.run(count: 1, name: "Falcon Redirector") do |task, instance|
				redirection = self.redirection(secure_endpoint)
				
				redirection_server = Falcon::Server.new(redirection, insecure_endpoint)
				
				redirection_server.run
			end
			
			return container
		end
	end
end
