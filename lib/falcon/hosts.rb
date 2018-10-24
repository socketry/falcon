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

require 'async/container/forked'

module Falcon
	class Host
		def initialize
			@app = nil
			@app_root = nil
			@config_path = "config.ru"
			
			@endpoint = nil
			
			@ssl_certificate = nil
			@ssl_key = nil
			
			@ssl_context = nil
		end
		
		attr_accessor :app
		attr_accessor :app_root
		attr_accessor :config_path
		
		attr_accessor :endpoint
		
		attr_accessor :ssl_certificate
		attr_accessor :ssl_key
		
		attr_accessor :ssl_context
		
		def freeze
			return if frozen?
			
			ssl_context
			
			super
		end
		
		def app?
			@app || @config_path
		end
		
		def load_app(verbose = false)
			return @app if @app
			
			if @config_path
				rack_app, options = Rack::Builder.parse_file(@config_path)
				
				return Server.middleware(rack_app, verbose: verbose)
			end
		end
		
		def self_signed!(hostname)
			authority = Localhost::Authority.fetch(hostname)
			
			@ssl_context = authority.server_context.tap do |context|
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
		
		def ssl_certificate_path= path
			@ssl_certificate = OpenSSL::X509::Certificate.new(File.read(path))
		end
		
		def ssl_key_path= path
			@ssl_key = OpenSSL::PKey::RSA.new(File.read(path))
		end
		
		def ssl_context
			@ssl_context ||= OpenSSL::SSL::SSLContext.new.tap do |context|
				context.cert = @ssl_certificate
				context.key = @ssl_key
				
				context.session_id_context = "falcon"
				
				context.set_params
				
				context.setup
			end
		end
		
		def start(*args)
			if self.app?
				Async::Container::Forked.new do
					Dir.chdir(@app_root) if @app_root
					
					app = self.load_app(*args)
					
					server = Falcon::Server.new(app, self.server_endpoint)
					
					server.run
				end
			end
		end
	end
	
	class Hosts
		DEFAULT_ALPN_PROTOCOLS = ['h2', 'http/1.1'].freeze
		
		def initialize
			@named = {}
			@server_context = nil
			@server_endpoint = nil
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
				@named.collect{|name, host| [name, host.endpoint]}
			]
		end
		
		def proxy
			Proxy.new(Falcon::BadRequest, self.client_endpoints)
		end
		
		def redirection
			Redirection.new(Falcon::BadRequest, self.client_endpoints)
		end
		
		def call(controller)
			self.each do |name, host|
				if container = host.start
					controller << container
				end
			end

			proxy = hosts.proxy
			debug_trap = Async::IO::Trap.new(:USR1)

			profile = RubyProf::Profile.new(merge_fibers: true)

			controller << Async::Container::Forked.new do |task|
				Process.setproctitle("Falcon Proxy")
				
				server = Falcon::Server.new(
					proxy,
					Async::HTTP::URLEndpoint.parse(
						'https://0.0.0.0',
						reuse_address: true,
						ssl_context: hosts.ssl_context
					)
				)
				
				Async::Reactor.run do |task|
					task.async do
						debug_trap.install!
						$stderr.puts "Send `kill -USR1 #{Process.pid}` for detailed status :)"
						
						debug_trap.trap do
							task.reactor.print_hierarchy($stderr)
							# Async.logger.level = Logger::DEBUG
						end
					end
					
					task.async do |task|
						start_time = Async::Clock.now
						
						while true
							task.sleep(600)
							duration = Async::Clock.now - start_time
							puts "Handled #{proxy.count} requests; #{(proxy.count.to_f / duration.to_f).round(1)} requests per second."
						end
					end
					
					$stderr.puts "Starting server"
					server.run
				end
			end
		end
	end
end
