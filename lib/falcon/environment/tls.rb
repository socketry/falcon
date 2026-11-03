# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2026, by Samuel Williams.

require_relative "../tls"
require_relative "../environment"

module Falcon
	module Environment
		# Provides an environment that exposes a TLS context for hosting a secure web application.
		module TLS
			# The default session identifier for the session cache.
			# @returns [String]
			def ssl_session_id
				"falcon"
			end
			
			# The supported ciphers.
			# @returns [Array(String)]
			def ssl_ciphers
				Falcon::TLS::SERVER_CIPHERS
			end
			
			# The public certificate path.
			# @returns [String]
			def ssl_certificate_path
				File.expand_path("ssl/certificate.pem", root)
			end
			
			# The list of certificates loaded from that path.
			# @returns [Array(OpenSSL::X509::Certificate)]
			def ssl_certificates
				OpenSSL::X509::Certificate.load_file(ssl_certificate_path)
			end
			
			# The main certificate.
			# @returns [OpenSSL::X509::Certificate]
			def ssl_certificate
				ssl_certificates[0]
			end
			
			# The certificate chain.
			# @returns [Array(OpenSSL::X509::Certificate)]
			def ssl_certificate_chain
				ssl_certificates[1..-1]
			end
			
			# The private key path.
			# @returns [String]
			def ssl_private_key_path
				File.expand_path("ssl/private.key", root)
			end
			
			# The private key.
			# @returns [OpenSSL::PKey::RSA]
			def ssl_private_key
				OpenSSL::PKey::RSA.new(File.read(ssl_private_key_path))
			end
			
			# The SSL context to use for incoming connections.
			# @returns [OpenSSL::SSL::SSLContext]
			def ssl_context
				OpenSSL::SSL::SSLContext.new.tap do |context|
					context.add_certificate(ssl_certificate, ssl_private_key, ssl_certificate_chain)
					
					context.session_cache_mode = OpenSSL::SSL::SSLContext::SESSION_CACHE_CLIENT
					context.session_id_context = ssl_session_id
					
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
					
					# Require at least TLS 1.2, but allow newer versions (e.g. TLS 1.3) to be negotiated. Using `ssl_version=` would pin both the minimum and maximum version to TLS 1.2.
					context.min_version = OpenSSL::SSL::TLS1_2_VERSION
					
					context.set_params(
						ciphers: ssl_ciphers,
						verify_mode: OpenSSL::SSL::VERIFY_NONE,
					)
					
					context.setup
				end
			end
		end
		
	end
end
