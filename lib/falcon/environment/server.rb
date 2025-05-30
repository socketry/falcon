# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2025, by Samuel Williams.

require "async/service/generic"
require "async/http/endpoint"

require_relative "../service/server"
require_relative "../server"

module Falcon
	module Environment
		# Provides an environment for hosting a web application that uses a Falcon server.
		module Server
			# The service class to use for the proxy.
			# @returns [Class]
			def service_class
				Service::Server
			end
			
			# The server authority. Defaults to the server name.
			# @returns [String]
			def authority
				self.name
			end
			
			# Number of instances to start. By default (when nil), uses `Etc.nprocessors`.
			# @returns [Integer | nil]
			def count
				nil
			end
			
			# Options to use when creating the container.
			def container_options
				{
					restart: true,
					count: self.count,
					health_check_timeout: 30,
				}.compact
			end
			
			# The host that this server will receive connections for.
			def url
				"http://[::]:9292"
			end
			
			# The timeout used for client connections.
			def timeout
				nil
			end
			
			# Options to use when creating the endpoint.
			def endpoint_options
				{
					reuse_address: true,
					timeout: self.timeout,
				}
			end
			
			# The upstream endpoint that will handle incoming requests.
			# @returns [Async::HTTP::Endpoint]
			def endpoint
				::Async::HTTP::Endpoint.parse(url).with(**endpoint_options)
			end
			
			# Whether to enable verbose logging.
			def verbose
				false
			end
			
			# Whether to enable the HTTP cache for this server.
			def cache
				false
			end
			
			# A client endpoint that can be used to connect to the server.
			# @returns [Async::HTTP::Endpoint] The client endpoint.
			def client_endpoint
				::Async::HTTP::Endpoint.parse(url)
			end
			
			# Any scripts to preload before starting the server.
			#
			# @returns [Array(String)] The list of scripts to preload.
			def preload
				[]
			end
			
			# Make a server instance using the given endpoint. The endpoint may be a bound endpoint, so we take care to specify the protocol and scheme as per the original endpoint.
			#
			# @parameter endpoint [IO::Endpoint] The endpoint to bind to.
			# @returns [Falcon::Server] The server instance.
			def make_server(endpoint)
				Falcon::Server.new(self.middleware, endpoint, protocol: self.endpoint.protocol, scheme: self.endpoint.scheme)
			end
		end
	end
end
