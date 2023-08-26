# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2020, by Samuel Williams.
# Copyright, 2020, by Daniel Evans.

require_relative '../proxy_endpoint'
require_relative '../server'

require_relative '../service/application'

# A general application environment.
# Suitable for use with any {Protocol::HTTP::Middleware}.
#
# @scope Falcon Environments
# @name application
environment(:application) do
	# The middleware stack for the application.
	# @attribute [Protocol::HTTP::Middleware]
	middleware do
		::Protocol::HTTP::Middleware::HelloWorld
	end
	
	# The scheme to use to communicate with the application.
	# @attribute [String]
	scheme 'https'
	
	# The protocol to use to communicate with the application.
	#
	# Typically one of {Async::HTTP::Protocol::HTTP1} or {Async::HTTP::Protocl::HTTP2}.
	#
	# @attribute [Async::HTTP::Protocol]
	protocol {Async::HTTP::Protocol::HTTP2}
	
	# The IPC path to use for communication with the application.
	# @attribute [String]
	ipc_path {::File.expand_path("application.ipc", root)}
	
	# The endpoint that will be used for communicating with the application server.
	# @attribute [Async::IO::Endpoint]
	endpoint do
		::Falcon::ProxyEndpoint.unix(ipc_path,
			protocol: protocol,
			scheme: scheme,
			authority: authority
		)
	end
	
	# The service class to use for the application.
	# @attribute [Class]
	service ::Falcon::Service::Application
	
	# Number of instances to start.
	# @attribute [Integer | nil]
	count nil
end
