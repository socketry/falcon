# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2022, by Samuel Williams.

module Falcon
	module TLS
		# The list of supported ciphers.
		#
		# We follow "Intermediate compatibility" as oulined here:
		# <https://wiki.mozilla.org/Security/Server_Side_TLS>
		SERVER_CIPHERS = [
			# TLS 1.3:
			"TLS_AES_128_GCM_SHA256",
			"TLS_AES_256_GCM_SHA384",
			"TLS_CHACHA20_POLY1305_SHA256",
			
			# TLS 1.2:
			"ECDHE-ECDSA-AES128-GCM-SHA256",
			"ECDHE-RSA-AES128-GCM-SHA256",
			"ECDHE-ECDSA-AES256-GCM-SHA384",
			"ECDHE-RSA-AES256-GCM-SHA384",
			"ECDHE-ECDSA-CHACHA20-POLY1305",
			"ECDHE-RSA-CHACHA20-POLY1305",
			"DHE-RSA-AES128-GCM-SHA256",
			"DHE-RSA-AES256-GCM-SHA384"
		].freeze
	end
end
