# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2024, by Samuel Williams.

require "async/http/client"

module Falcon
	module Middleware
		# A static middleware which always returns a 404 not found response.
		module NotFound
			def self.call(request)
				return Protocol::HTTP::Response[404, {}, []]
			end
			
			def self.close
			end
		end
		
		# A HTTP middleware for redirecting a given set of hosts to a different endpoint.
		# Typically used for implementing HTTP -> HTTPS redirects.
		class Redirect < Protocol::HTTP::Middleware
			# Initialize the redirect middleware.
			# @parameter app [Protocol::HTTP::Middleware] The middleware to wrap.
			# @parameter hosts [Hash(String, Service::Proxy)] The map of hosts.
			# @parameter endpoint [Endpoint] The template endpoint to use to build the redirect location.
			def initialize(app, hosts, endpoint)
				super(app)
				
				@hosts = hosts
				@endpoint = endpoint
			end
			
			# Lookup the appropriate host for the given request.
			# @parameter request [Protocol::HTTP::Request]
			def lookup(request)
				# Trailing dot and port is ignored/normalized.
				if authority = request.authority&.sub(/(\.)?(:\d+)?$/, "")
					return @hosts[authority]
				end
			end
			
			# Redirect the request if the authority matches a specific host.
			# @parameter request [Protocol::HTTP::Request]
			def call(request)
				if host = lookup(request)
					if @endpoint.default_port?
						location = "#{@endpoint.scheme}://#{host.authority}#{request.path}"
					else
						location = "#{@endpoint.scheme}://#{host.authority}:#{@endpoint.port}#{request.path}"
					end
					
					return Protocol::HTTP::Response[301, [["location", location]], []]
				else
					super
				end
			end
			
			Traces::Provider(self) do
				def call(request)
					Traces.trace("falcon.middleware.redirect.call", attributes: {authority: request.authority}) do
						super
					end
				end
			end
		end
	end
end
