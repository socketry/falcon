# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2024, by Samuel Williams.

require_relative 'server'
require_relative '../tls'
require_relative '../middleware/proxy'

module Falcon
	module Environments
		module Proxy
			include Server
			
			# The host that this proxy will receive connections for.
			def url
				"https://[::]:443"
			end
			
			# The default SSL session identifier.
			def tls_session_id
				"falcon"
			end
			
			# The services we will proxy to.
			# @returns [Array(Async::Service::Environment)]
			def environments
				[]
			end
			
			def hosts
				hosts = {}
				
				environments.each do |environment|
					evaluator = environment.evaluator
					
					if evaluator.key?(:authority) and evaluator.key?(:ssl_context) and evaluator.key?(:endpoint)
						Console.logger.info(self) {"Proxying #{self.url} to #{evaluator.authority} using #{evaluator.endpoint}"}
						hosts[evaluator.authority] = evaluator
						
						# Pre-cache the ssl contexts:
						# It seems some OpenSSL objects don't like event-driven I/O.
						# service.ssl_context
					else
						Console.logger.warn(self) {"Ignoring environment: #{environment}, missing authority, ssl_context, or endpoint."}
					end
				end
				
				return hosts
			end
			
			# Look up the host context for the given hostname, and update the socket hostname if necessary.
			# @parameter socket [OpenSSL::SSL::SSLSocket] The incoming connection.
			# @parameter hostname [String] The negotiated hostname.
			def host_context(socket, hostname)
				hosts = self.hosts
				
				if host = hosts[hostname]
					Console.logger.debug(self) {"Resolving #{hostname} -> #{host}"}
					
					socket.hostname = hostname
					
					return host.ssl_context
				else
					Console.logger.warn(self, hosts: hosts.keys) {"Unable to resolve #{hostname}!"}
					
					return nil
				end
			end
			
			# Generate an SSL context which delegates to {host_context} to multiplex based on hostname.
			def ssl_context
				@server_context ||= OpenSSL::SSL::SSLContext.new.tap do |context|
					context.servername_cb = Proc.new do |socket, hostname|
						self.host_context(socket, hostname)
					end
					
					context.session_id_context = @session_id
					
					context.ssl_version = :TLSv1_2_server
					
					context.set_params(
						ciphers: ::Falcon::TLS::SERVER_CIPHERS,
						verify_mode: ::OpenSSL::SSL::VERIFY_NONE,
					)
					
					context.setup
				end
			end
			
			# The endpoint the server will bind to.
			def endpoint
				super.with(
					ssl_context: self.ssl_context,
				)
			end
			
			def middleware
				return Middleware::Proxy.new(Middleware::BadRequest, self.hosts)
			end
		end
		
		LEGACY_ENVIRONMENTS[:proxy] = Proxy
	end
end
