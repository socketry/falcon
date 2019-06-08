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

require_relative 'host'
require_relative 'proxy'
require_relative 'redirection'

require 'async/container'
require 'async/container/controller'
require 'async/http/endpoint'

module Falcon
	class Hosts
		DEFAULT_ALPN_PROTOCOLS = ['h2', 'http/1.1'].freeze
		SERVER_CIPHERS = "EECDH+CHACHA20:EECDH+AES128:RSA+AES128:EECDH+AES256:RSA+AES256:EECDH+3DES:RSA+3DES:!MD5".freeze
		
		def initialize(configuration)
			@named = {}
			@server_context = nil
			@server_endpoint = nil
			
			configuration.each(:authority) do |environment|
				add(Host.new(environment))
			end
		end
		
		def each(&block)
			@named.each_value(&block)
		end
		
		def endpoint
			@server_endpoint ||= Async::HTTP::Endpoint.parse(
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
				
				context.set_params(
					ciphers: SERVER_CIPHERS,
					verify_mode: OpenSSL::SSL::VERIFY_NONE,
				)
				
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
		
		def run(container = Async::Container.new, **options)
			secure_endpoint = Async::HTTP::Endpoint.parse(options[:bind_secure], ssl_context: self.ssl_context)
			insecure_endpoint = Async::HTTP::Endpoint.parse(options[:bind_insecure])
			
			secure_endpoint_bound = insecure_endpoint_bound = nil
			
			Async::Reactor.run do
				secure_endpoint_bound = Async::IO::SharedEndpoint.bound(secure_endpoint)
				insecure_endpoint_bound = Async::IO::SharedEndpoint.bound(insecure_endpoint)
			end.wait
			
			container.run(name: "Falcon Proxy", restart: true) do |task, instance|
				proxy = self.proxy
				
				proxy_server = Falcon::Server.new(proxy, secure_endpoint_bound, secure_endpoint.protocol, secure_endpoint.scheme)
				
				proxy_server.run
			end
			
			container.run(name: "Falcon Redirector", restart: true) do |task, instance|
				redirection = self.redirection(secure_endpoint)
				
				redirection_server = Falcon::Server.new(redirection, insecure_endpoint_bound, insecure_endpoint.protocol, insecure_endpoint.scheme)
				
				redirection_server.run
			end
			
			container.attach do
				secure_endpoint_bound.close
				insecure_endpoint_bound.close
			end
			
			return container
		end
	end
end
