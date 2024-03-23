# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2024, by Samuel Williams.

require_relative 'tls'
require_relative '../environment'

module Falcon
	module Environment
		# Provides an environment that uses "Lets Encrypt" for TLS.
		module LetsEncryptTLS
			# The Lets Encrypt certificate store path.
			# @parameter [String]
			def lets_encrypt_root
				'/etc/letsencrypt/live'
			end
			
			# The public certificate path.
			# @attribute [String]
			def ssl_certificate_path
				File.join(lets_encrypt_root, authority, "fullchain.pem")
			end
			
			# The private key path.
			# @attribute [String]
			def ssl_private_key_path
				File.join(lets_encrypt_root, authority, "privkey.pem")
			end
		end
		
		LEGACY_ENVIRONMENTS[:tls] = TLS
	end
end
