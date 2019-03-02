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

module Falcon
	class Configuration
		def initialize
			@environments = {}
			
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
				ssl_session_id {"falcon"}
				
				ssl_context do
					authority = Localhost::Authority.fetch(hostname)
					
					authority.server_context.tap do |context|
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
				application {::Rack::Builder.parse_file(config_path)}
				middleware {::Falcon::Server.middleware(*application)}
				
				endpoint {::Async::HTTP::URLEndpoint.parse(url)}
			end
		end
		
		attr :environments
		
		def add(name, parent = nil, &block)
			parent = @environments.fetch(parent, parent)
			
			@environments[name] = Build::Environment.new(parent, {hostname: name}, name: name, &block)
		end
		
		def each
			return to_enum unless block_given?
			
			@environments.each do |environment|
				if environment.include?(:hostname)
					yield environment
				end
			end
		end
		
		def host(name, &block)
			add(name, :host, &block)
		end
		
		def proxy(name, &block)
			add(name, :proxy, &block)
		end
		
		def rack(name, &block)
			add(name, :rack, &block)
		end
		
		def load_file(path)
			self.instance_eval(File.read(path), path)
		end
	end
end
