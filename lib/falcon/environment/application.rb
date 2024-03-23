# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2024, by Samuel Williams.
# Copyright, 2020, by Daniel Evans.

require_relative 'server'
require_relative '../proxy_endpoint'

module Falcon
	module Environment
		module Application
			include Server
			
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
			
			# Number of instances to start.
			# @returns [Integer | nil]
			def count
				nil
			end
		end
	end
end
