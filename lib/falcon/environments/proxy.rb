# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2023, by Samuel Williams.

require_relative '../service/proxy'
require_relative '../environments'

module Falcon
	module Environments
		# A HTTP proxy environment.
		module Proxy
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
		end
		
		LEGACY_ENVIRONMENTS[:proxy] = Proxy
	end
end
