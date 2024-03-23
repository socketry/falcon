# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2024, by Samuel Williams.

require_relative 'server'
require_relative '../middleware/redirect'

module Falcon
	module Environments
		# A controller for redirecting requests.
		module Redirect
			include Server
			
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
	end
end
