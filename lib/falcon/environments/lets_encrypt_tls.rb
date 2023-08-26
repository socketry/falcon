# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020, by Samuel Williams.

load(:tls)

# A Lets Encrypt SSL context environment.
#
# Derived from {.tls}.
#
# @scope Falcon Environments
# @name lets_encrypt_tls
environment(:lets_encrypt_tls, :tls) do
	# The Lets Encrypt certificate store path.
	# @parameter [String]
	lets_encrypt_root '/etc/letsencrypt/live'
	
	# The public certificate path.
	# @attribute [String]
	ssl_certificate_path do
		File.join(lets_encrypt_root, authority, "fullchain.pem")
	end
	
	# The private key path.
	# @attribute [String]
	ssl_private_key_path do
		File.join(lets_encrypt_root, authority, "privkey.pem")
	end
end
