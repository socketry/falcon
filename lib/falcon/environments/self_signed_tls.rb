# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2020, by Samuel Williams.

require 'localhost/authority'

# A self-signed SSL context environment.
#
# @scope Falcon Environments
# @name self_signed_tls
environment(:self_signed_tls) do
	# The default session identifier for the session cache.
	# @attribute [String]
	ssl_session_id {"falcon"}
	
	# The SSL context to use for incoming connections.
	# @attribute [OpenSSL::SSL::SSLContext]
	ssl_context do
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
