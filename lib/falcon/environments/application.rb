# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2023, by Samuel Williams.
# Copyright, 2020, by Daniel Evans.

require_relative '../proxy_endpoint'
require_relative '../server'

require_relative '../service/application'
require_relative '../environments'

module Falcon
	module Environments
		# A general application environment. Suitable for use with any {Protocol::HTTP::Middleware}.
		module Application
			# The middleware stack for the application.
			# @returns [Protocol::HTTP::Middleware]
			def middleware
				::Protocol::HTTP::Middleware::HelloWorld
			end
			
			# The scheme to use to communicate with the application.
			# @returns [String]
			def scheme
				'https'
			end
			
			# The protocol to use to communicate with the application.
			#
			# Typically one of {Async::HTTP::Protocol::HTTP1} or {Async::HTTP::Protocl::HTTP2}.
			#
			# @returns [Async::HTTP::Protocol]
			def protocol
				Async::HTTP::Protocol::HTTP2
			end
			
			# The IPC path to use for communication with the application.
			# @returns [String]
			def ipc_path
				::File.expand_path("application.ipc", root)
			end
			
			# The endpoint that will be used for communicating with the application server.
			# @returns [Async::IO::Endpoint]
			def endpoint
				::Falcon::ProxyEndpoint.unix(ipc_path,
					protocol: protocol,
					scheme: scheme,
					authority: authority
				)
			end
			
			# The service class to use for the application.
			# @returns [Class]
			def service_class
				::Falcon::Service::Application
			end
			
			# Number of instances to start.
			# @returns [Integer | nil]
			def count
				nil
			end
			
			def preload
				[]
			end
		end
		
		LEGACY_ENVIRONMENTS[:application] = Application
	end
end
