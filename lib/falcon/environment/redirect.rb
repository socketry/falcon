# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2024, by Samuel Williams.

require_relative "server"
require_relative "../middleware/redirect"

module Falcon
	module Environment
		# Provides an environment for redirecting insecure web traffic to a secure endpoint.
		module Redirect
			include Server
			
			def redirect_url
				"https://[::]:443"
			end
			
			def redirect_endpoint
				Async::HTTP::Endpoint.parse(redirect_url)
			end
			
			# The services we will redirect to.
			# @returns [Array(Async::Service::Environment)]
			def environments
				[]
			end
			
			def hosts
				hosts = {}
				
				environments.each do |environment|
					evaluator = environment.evaluator
					
					if environment.implements?(Falcon::Environment::Application)
						Console.info(self) {"Redirecting #{self.url} to #{evaluator.authority}"}
						hosts[evaluator.authority] = evaluator
					end
				end
				
				return hosts
			end
			
			# Load the {Middleware::Redirect} application with the specified hosts.
			def middleware
				Middleware::Redirect.new(Middleware::NotFound, hosts, redirect_endpoint)
			end
		end
	end
end
