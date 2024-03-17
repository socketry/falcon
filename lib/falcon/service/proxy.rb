# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2023, by Samuel Williams.

require 'async/service/generic'

require 'async/http/endpoint'
require 'async/io/shared_endpoint'

module Falcon
	module Service
		class Proxy < Async::Service::Generic
			module Environment
				# The host that this proxy will receive connections for.
				def url
					"https://[::]:443"
				end
				
				# The upstream endpoint that will handle incoming requests.
				# @attribute [Async::HTTP::Endpoint]
				def endpoint
					::Async::HTTP::Endpoint.parse(url)
				end
				
				# The service class to use for the proxy.
				# @attribute [Class]
				def service_class
					::Falcon::Service::Proxy
				end
				
				# The default SSL session identifier.
				def tls_session_id
					"falcon"
				end
				
				def hosts
					services.each do |service|
						if service.is_a?(Service::Proxy)
							Console.logger.info(self) {"Proxying #{service.authority} to #{service.endpoint}"}
							@hosts[service.authority] = service
							
							# Pre-cache the ssl contexts:
							# It seems some OpenSSL objects don't like event-driven I/O.
							service.ssl_context
						end
					end
				end
				
				def middleware
					return Middleware::Proxy.new(Middleware::BadRequest, hosts)
				end
			end
			
			def self.included(target)
				target.include(Environment)
			end
			
			def name
				"#{self.class} for #{self.authority}"
			end
			
			# The host that this proxy will receive connections for.
			def authority
				@evaluator.authority
			end
			
			# The upstream endpoint that this proxy will connect to.
			def endpoint
				@evaluator.endpoint
			end
			
			# The {OpenSSL::SSL::SSLContext} that will be used for incoming connections.
			def ssl_context
				@evaluator.ssl_context
			end
			
			# The root
			def root
				@evaluator.root
			end
			
			# The protocol this proxy will use to talk to the upstream host.
			def protocol
				endpoint.protocol
			end
			
			# The scheme this proxy will use to talk to the upstream host.
			def scheme
				endpoint.scheme
			end
		end
	end
end
