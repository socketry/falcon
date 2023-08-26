# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020, by Samuel Williams.

require_relative 'generic'

require 'async/http/endpoint'
require 'async/io/shared_endpoint'

module Falcon
	module Service
		class Proxy < Generic
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
