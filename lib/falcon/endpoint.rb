# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2025, by Samuel Williams.

require "async/http/endpoint"
require "localhost/authority"

module Falcon
	# An HTTP-specific endpoint which adds localhost TLS.
	class Endpoint < Async::HTTP::Endpoint
		# The SSL context to use, which invokes {build_ssl_context} if not otherwise specified.
		# @returns [OpenSSL::SSL::SSLContext]
		def ssl_context
			@options[:ssl_context] || build_ssl_context
		end
		
		# Build an appropriate SSL context for the given hostname.
		#
		# Uses {Localhost::Authority} to generate self-signed certficates.
		#
		# @returns [OpenSSL::SSL::SSLContext]
		def build_ssl_context(hostname = self.hostname)
			authority = Localhost::Authority.fetch(hostname)
			
			authority.server_context.tap do |context|
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
				
				context.session_id_context = "falcon"
			end
		end
	end
end
