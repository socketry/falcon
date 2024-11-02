# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2024, by Samuel Williams.

require "localhost/authority"
require_relative "tls"
require_relative "../environment"

module Falcon
	module Environment
		# Provides an environment that exposes a self-signed TLS certificate using the `localhost` gem.
		module SelfSignedTLS
			# The default session identifier for the session cache.
			# @returns [String]
			def ssl_session_id
				"falcon"
			end
			
			# The SSL context to use for incoming connections.
			# @returns [OpenSSL::SSL::SSLContext]
			def ssl_context
				contexts = Localhost::Authority.fetch(authority)
				
				contexts.server_context.tap do |context|
					context.alpn_select_cb = lambda do |protocols|
						if protocols.include? "h2"
							return "h2"
						elsif protocols.include? "http/1.1"
							return "http/1.1"
						elsif protocols.include? "http/1.0"
							return "http/1.0"
						else
							return nil
						end
					end
					
					context.session_id_context = ssl_session_id
				end
			end
		end
		
		LEGACY_ENVIRONMENTS[:self_signed_tls] = SelfSignedTLS
	end
end
