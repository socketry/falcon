# frozen_string_literal: true

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

require_relative 'serve'
require_relative '../middleware/proxy'
require_relative '../service/proxy'

require_relative '../tls'

module Falcon
	module Controller
		class Proxy < Serve
			DEFAULT_SESSION_ID = "falcon"
			
			def initialize(command, session_id: DEFAULT_SESSION_ID, **options)
				super(command, **options)
				
				@session_id = session_id
				@hosts = {}
			end
			
			def load_app
				return Middleware::Proxy.new(Middleware::BadRequest, @hosts)
			end
			
			def name
				"Falcon Proxy Server"
			end
			
			def host_context(socket, hostname)
				if host = @hosts[hostname]
					Async.logger.debug(self) {"Resolving #{hostname} -> #{host}"}
					
					socket.hostname = hostname
					
					return host.ssl_context
				else
					Async.logger.warn(self) {"Unable to resolve #{hostname}!"}
					
					return nil
				end
			end
			
			def ssl_context
				@server_context ||= OpenSSL::SSL::SSLContext.new.tap do |context|
					context.servername_cb = Proc.new do |socket, hostname|
						self.host_context(socket, hostname)
					end
					
					context.session_id_context = @session_id
					
					context.ssl_version = :TLSv1_2_server
					
					context.set_params(
						ciphers: TLS::SERVER_CIPHERS,
						verify_mode: OpenSSL::SSL::VERIFY_NONE,
					)
					
					context.setup
				end
			end
			
			def endpoint
				@command.endpoint.with(
					ssl_context: self.ssl_context,
					reuse_address: true,
				)
			end
			
			def before_serve
				# require 'memory_profiler'
				# MemoryProfiler.start
			end
			
			def instance_ready(server, parent: Async::Task.current)
				# parent.async do |task|
				# 	task.sleep(20)
				# 
				# 	Async.logger.info(self) {"Preparing memory report..."}
				# 
				# 	require 'objspace'
				# 	ObjectSpace.trace_object_allocations_start
				# 
				# 	File.open("heap-#{Process.pid}.dump", 'w') do |file|
				# 		ObjectSpace.dump_all(output: file)
				# 	end
				# end
				# 
				# 	report = MemoryProfiler.stop
				# 	report.pretty_print($stderr)
				# 
				# 	ObjectSpace.each_object(Async::HTTP::Protocol::HTTP2::Server) do |server|
				# 		Async.logger.info(server) {server.inspect}
				# 	end
				# 
				# 	clients = server.delegate.clients
				# 	clients.each do |key, client|
				# 		Async.logger.info(self) do |buffer|
				# 			buffer.puts "Client for #{key}: #{client.pool}"
				# 
				# 			pool = client.pool
				# 			pool.resources.each do |connection, usage|
				# 				buffer.puts "\t#{usage}: #{connection}"
				# 				connection.streams.each do |key, stream|
				# 					buffer.puts "\t\t#{key} -> #{stream}"
				# 				end
				# 			end
				# 		end
				# 	end
				# end
			end
			
			def start
				if GC.respond_to?(:compact)
					GC.compact
				end
				
				configuration = @command.configuration
				
				services = Services.new(configuration)
				
				@hosts = {}
				
				services.each do |service|
					if service.is_a?(Service::Proxy)
						Async.logger.info(self) {"Proxying #{service.authority} to #{service.endpoint}"}
						@hosts[service.authority] = service
					end
				end
				
				super
			end
		end
	end
end
