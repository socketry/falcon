# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2023, by Samuel Williams.

require 'async/container/controller'

# require_relative 'serve'
require_relative '../middleware/redirect'
require_relative '../service/proxy'

module Falcon
	module Service
		# A controller for redirecting requests.
		class Redirect < Server
			module Environment
				include Server::Environment
				
				def redirect_url
					"https://[::]:443"
				end
				
				def redirect_endpoint
					Async::HTTP::Endpoint.parse(redirect_url)
				end
				
				def hosts
					{}
				end
				
				# Load the {Middleware::Redirect} application with the specified hosts.
				def middleware
					Middleware::Redirect.new(Middleware::NotFound, hosts, redirect_endpoint)
				end
			end
			
			# services.each do |service|
			# 	if service.is_a?(Service::Proxy)
			# 		@hosts[service.authority] = service
			# 	end
			# end
		end
	end
end
