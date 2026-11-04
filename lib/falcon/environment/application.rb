# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2024, by Samuel Williams.
# Copyright, 2020, by Daniel Evans.

require_relative "server"
require_relative "../proxy_endpoint"

module Falcon
	module Environment
		# Provides an environment for hosting a web application that uses TLS.
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
				"https"
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
			
			# The file mode applied to the IPC socket after it is bound.
			#
			# The proxy adds `x-forwarded-for`, `x-forwarded-proto` and `forwarded` headers which the application trusts, so the socket must not be connectable by other local users. Connecting requires write permission on the socket file, so the default (`0o600`) permits only the owner (and root). Use `ipc_mode 0o660` if a separate front-end proxy (e.g. nginx) running in the application's group needs to connect, or `ipc_mode nil` to leave the permissions as determined by the process umask.
			#
			# Note that restricting the application root directory itself (e.g. `0o700`) is a stronger control; the socket mode only matters when other users can traverse the application root.
			#
			# @returns [Integer | Nil] The file mode, or `nil` to leave the permissions as determined by the process umask.
			def ipc_mode
				::Falcon::ProxyEndpoint::DEFAULT_MODE
			end
			
			# The endpoint that will be used for communicating with the application server.
			# @returns [::Falcon::ProxyEndpoint]
			def endpoint
				::Falcon::ProxyEndpoint.unix(ipc_path,
					protocol: protocol,
					scheme: scheme,
					authority: authority,
					mode: ipc_mode,
				)
			end
		end
	end
end
