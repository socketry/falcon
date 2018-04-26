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

module Falcon
	class Host
		def initialize
			@app = nil
			@endpoint = nil
			@ssl_certificate = nil
			@ssl_key = nil
		end
		
		attr_accessor :app
		
		attr_accessor :endpoint
		attr_accessor :client_endpoint
		
		attr_accessor :ssl_certificate
		attr_accessor :ssl_key
		
		# A client would connect to this endpoint
		def proxy_endpoint
			if ssl_context = self.ssl_context
				Async::IO::SecureEndpoint.new()
			else
				@endpoint
			end
		end
		
		# The app will bind to this endpoint
		def server_endpoint
		end
		
		def ssl_certificate_path= path
			@ssl_certificate = OpenSSL::X509::Certificate.new(File.read(path))
		end
		
		def ssl_key_path= path
			@ssl_key = OpenSSL::PKey::RSA.new(File.read(path))
		end
		
		def ssl_context
			if @ssl_key
				OpenSSL::SSL::SSLContext.new.tap do |context|
					context.cert = @ssl_certificate
					context.key = @ssl_key
					
					context.set_params
				end
			end
		end
		
		def start
			if app = self.app
				Async::Container::Forked.new do
					server = Falcon::Server.new(app, self.server_endpoint)
					
					server.run
				end
			end
		end
	end
	
	class Hosts
		def initialize
			@named = {}
			@server_context = nil
			@server_endpoint = nil
		end
		
		def endpoint
			@server_endpoint ||= Async::IO::SecureEndpoint.new(
				Async::IO::Endpoint.tcp('0.0.0.0', 443),
				ssl_context: self.ssl_context
			)
		end
		
		def ssl_context
			@server_context ||= OpenSSL::SSL::SSLContext.new.tap do |context|
				context.servername_cb = self.method(:host_context)
				
				context.set_params
			end
		end
		
		def host_context(socket, hostname)
			if host = @named[hostname]
				socket.hostname = hostname
				
				return host.ssl_context
			end
		end
		
		def add(name, host = Host.new, &block)
			host = Host.new
			
			yield host if block_given?
			
			@named[name] = host.freeze
		end
		
		def client_endpoints
			Hash[
				@named.collect{|name, host| [name, host.client_endpoint]}
			]
		end
	end
end
