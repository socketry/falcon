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

require 'build/environment'
require 'async/io/unix_endpoint'

module Falcon
	class ProxyEndpoint < Async::IO::Endpoint
		def initialize(endpoint, **options)
			super(**options)
			
			@endpoint = endpoint
		end
		
		attr :endpoint
		
		def protocol
			@options[:protocol]
		end
		
		def scheme
			@options[:scheme]
		end
		
		def authority
			@options[:authority]
		end
		
		def connect(&block)
			@endpoint.connect(&block)
		end
		
		def bind(&block)
			@endpoint.bind(&block)
		end
		
		def each
			return to_enum unless block_given?
			
			@endpoint.each do |endpoint|
				yield self.class.new(endpoint, @options)
			end
		end
		
		def self.unix(path, **options)
			self.new(::Async::IO::Endpoint.unix(path), **options)
		end
	end
	
	class Configuration
		def initialize(verbose = false)
			@environments = {}
			@verbose = verbose
			
			add(:ssl) do
				ssl_session_id {"falcon"}
			end
			
			add(:host, :ssl) do
				ssl_certificate_path {File.expand_path("ssl/certificate.pem", root)}
				ssl_certificate {OpenSSL::X509::Certificate.new(File.read(ssl_certificate_path))}
				
				ssl_private_key_path {File.expand_path("ssl/private.key", root)}
				ssl_private_key {OpenSSL::PKey::RSA.new(File.read(ssl_private_key_path))}
				
				ssl_context do
					OpenSSL::SSL::SSLContext.new.tap do |context|
						context.cert = ssl_certificate
						context.key = ssl_private_key
						
						context.session_id_context = ssl_session_id
						
						context.set_params
						
						context.setup
					end
				end
			end
			
			add(:self_signed, :ssl) do
				ssl_context do
					contexts = Localhost::Authority.fetch(authority)
					
					contexts.server_context.tap do |context|
						context.alpn_select_cb = lambda do |protocols|
							if protocols.include? "h2"
								return "h2"
							elsif protocols.include? "http/1.1"
								return "http/1.1"
							elsif protocols.include? "http/1.0"
								return "http/1.0"
							else
								return nil
							end
						end
						
						context.session_id_context = "falcon"
					end
				end
			end
			
			add(:proxy, :host) do
				endpoint {::Async::HTTP::URLEndpoint.parse(url)}
			end
			
			add(:rack, :host) do
				config_path {::File.expand_path("config.ru", root)}
				application {::Rack::Builder.parse_file(config_path).first}
				middleware {::Falcon::Server.middleware(application, verbose: verbose)}
				
				authority 'localhost'
				scheme 'https'
				protocol {::Async::HTTP::Protocol::HTTP2}
				ipc_path {::File.expand_path("server.ipc", root)}
				
				endpoint {ProxyEndpoint.unix(ipc_path, protocol: protocol, scheme: scheme, authority: authority)}
				
				bound_endpoint do
					Async::Reactor.run do
						Async::IO::SharedEndpoint.bound(endpoint)
					end.wait
				end
				
				server {::Falcon::Server.new(middleware, bound_endpoint, protocol, scheme)}
			end
		end
		
		attr :environments
		
		def add(name, *parents, &block)
			raise KeyError.new("#{name} is already set", key: name) if @environments.key?(name)
			
			environments = parents.map{|name| @environments.fetch(name)}
			
			parent = Build::Environment.combine(*environments)
			
			@environments[name] = Build::Environment.new(parent, name: name, &block)
		end
		
		def each
			return to_enum unless block_given?
			
			@environments.each do |name, environment|
				if environment.include?(:authority)
					yield environment
				end
			end
		end
		
		def host(name, *parents, &block)
			add(name, :host, *parents, &block).tap do |environment|
				environment[:authority] = name
			end
		end
		
		def proxy(name, *parents, &block)
			add(name, :proxy, *parents, &block).tap do |environment|
				environment[:authority] = name
			end
		end
		
		def rack(name, *parents, &block)
			add(name, :rack, *parents, &block).tap do |environment|
				environment[:authority] = name
			end
		end
		
		def load_file(path)
			self.instance_eval(File.read(path), path)
		end
	end
end
