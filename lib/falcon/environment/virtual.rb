# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024, by Samuel Williams.

require_relative 'configured'

require_relative '../service/virtual'

module Falcon
	module Environment
		module Virtual
			include Configured
			
			# The service class to use for the virtual host.
			# @returns [Class]
			def service_class
				Service::Virtual
			end
			
			def name
				service_class.name
			end
			
			# The URI to bind the `HTTPS` -> `falcon host` proxy.
			def bind_secure
				"https://[::]:443"
			end
			
			# The URI to bind the `HTTP` -> `HTTPS` redirector.
			def bind_insecure
				"http://[::]:80"
			end
			
			# The connection timeout to use for incoming connections.
			def timeout
				10.0
			end
			
			# The path to the falcon executable from this gem.
			# @returns [String]
			def falcon_path
				File.expand_path("../../../bin/falcon", __dir__)
			end
			
			# # The insecure endpoint for connecting to the {Redirect} instance.
			# def insecure_endpoint(**options)
			# 	Async::HTTP::Endpoint.parse(bind_insecure, **options)
			# end
			
			# # The secure endpoint for connecting to the {Proxy} instance.
			# def secure_endpoint(**options)
			# 	Async::HTTP::Endpoint.parse(bind_secure, **options)
			# end
			
			# # An endpoint suitable for connecting to the specified hostname.
			# def host_endpoint(hostname, **options)
			# 	endpoint = secure_endpoint(**options)
				
			# 	url = URI.parse(bind_secure)
			# 	url.hostname = hostname
				
			# 	return Async::HTTP::Endpoint.new(url, hostname: endpoint.hostname)
			# end
		end
	end
end
