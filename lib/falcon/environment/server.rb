# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024, by Samuel Williams.

require 'async/service/generic'
require 'async/http/endpoint'

require_relative '../service/server'
require_relative '../server'

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
			
			# Options to use when creating the container.
			def container_options
				{restart: true}
			end
			
			# The host that this server will receive connections for.
			def url
				"http://[::]:9292"
			end
			
			def timeout
				nil
			end
			
			# The upstream endpoint that will handle incoming requests.
			# @returns [Async::HTTP::Endpoint]
			def endpoint
				::Async::HTTP::Endpoint.parse(url).with(
					reuse_address: true,
					timeout: timeout,
				)
			end
			
			def verbose
				false
			end
			
			def cache
				false
			end
			
			def client_endpoint
				::Async::HTTP::Endpoint.parse(url)
			end
			
			# Any scripts to preload before starting the server.
			def preload
				[]
			end
		end
	end
end
