# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2023, by Samuel Williams.

require 'async/container/controller'

require_relative 'serve'
require_relative '../middleware/proxy'
require_relative '../service/proxy'

require_relative '../tls'

module Falcon
	module Controller
		# A controller for proxying requests.
		class Proxy < Serve
			# The default SSL session identifier.
			DEFAULT_SESSION_ID = "falcon"
			
			# Initialize the proxy controller.
			# @parameter command [Command::Proxy] The user-specified command-line options.
			# @parameter session_id [String] The SSL session identifier to use for the session cache.
			def initialize(command, session_id: DEFAULT_SESSION_ID, **options)
				super(command, **options)
				
				@session_id = session_id
				@hosts = {}
			end
			
			# Load the {Middleware::Proxy} application with the specified hosts.
			def load_app
				return Middleware::Proxy.new(Middleware::BadRequest, @hosts)
			end
			
			# The name of the controller which is used for the process title.
			def name
				"Falcon Proxy Server"
			end
			
			# Look up the host context for the given hostname, and update the socket hostname if necessary.
			# @parameter socket [OpenSSL::SSL::SSLSocket] The incoming connection.
			# @parameter hostname [String] The negotiated hostname.
			def host_context(socket, hostname)
				if host = @hosts[hostname]
					Console.logger.debug(self) {"Resolving #{hostname} -> #{host}"}
					
					socket.hostname = hostname
					
					return host.ssl_context
				else
					Console.logger.warn(self) {"Unable to resolve #{hostname}!"}
					
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
						ciphers: TLS::SERVER_CIPHERS,
						verify_mode: OpenSSL::SSL::VERIFY_NONE,
					)
					
					context.setup
				end
			end
			
			# The endpoint the server will bind to.
			def endpoint
				@command.endpoint.with(
					ssl_context: self.ssl_context,
					reuse_address: true,
				)
			end
			
			# Builds a map of host redirections.
			def start
				configuration = @command.configuration
				
				services = Services.new(configuration)
				
				@hosts = {}
				
				services.each do |service|
					if service.is_a?(Service::Proxy)
						Console.logger.info(self) {"Proxying #{service.authority} to #{service.endpoint}"}
						@hosts[service.authority] = service
						
						# Pre-cache the ssl contexts:
						# It seems some OpenSSL objects don't like event-driven I/O.
						service.ssl_context
					end
				end
				
				super
			end
		end
	end
end
