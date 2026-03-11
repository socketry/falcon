# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2026, by Samuel Williams.

require_relative "server"
require_relative "application"
require_relative "../middleware/redirect"

module Falcon
	module Environment
		# Provides an environment for redirecting insecure web traffic to a secure endpoint.
		module Redirect
			include Server
			
			# The URL template to redirect to.
			# @returns [String] The redirect URL template.
			def redirect_url
				"https://[::]:443"
			end
			
			# Parse the redirect URL into an endpoint.
			# @returns [Async::HTTP::Endpoint] The redirect endpoint.
			def redirect_endpoint
				Async::HTTP::Endpoint.parse(redirect_url)
			end
			
			# The services we will redirect to.
			# @returns [Array(Async::Service::Environment)]
			def environments
				[]
			end
			
			# Build a hash of host authorities to their evaluators for redirect matching.
			# @returns [Hash(String, Async::Service::Environment::Evaluator)] Map of host authorities to evaluators.
			def hosts
				hosts = {}
				
				environments.each do |environment|
					evaluator = environment.evaluator
					
					if environment.implements?(Falcon::Environment::Application)
						Console.info(self){"Redirecting #{self.url} to #{evaluator.authority}"}
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
