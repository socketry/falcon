# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2020, by Samuel Williams.

# A HTTP proxy environment.
#
# Derived from {.application}.
#
# @scope Falcon Environments
# @name rack
environment(:proxy) do
	# The upstream endpoint that will handle incoming requests.
	# @attribute [Async::HTTP::Endpoint]
	endpoint {::Async::HTTP::Endpoint.parse(url)}
	
	# The service class to use for the proxy.
	# @attribute [Class]
	service ::Falcon::Service::Proxy
end
