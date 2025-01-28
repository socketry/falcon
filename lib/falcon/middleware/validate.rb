# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

module Falcon
	module Middleware
		# A HTTP middleware for validating incoming requests.
		class Validate < Protocol::HTTP::Middleware
			# Initialize the validate middleware.
			# @parameter app [Protocol::HTTP::Middleware] The middleware to wrap.
			def initialize(app)
				super(app)
			end
			
			# Validate the incoming request.
			def call(request)
				unless request.path.start_with?("/")
					return Protocol::HTTP::Response[400, {}, ["Invalid request path!"]]
				end
				
				return super
			end
		end
	end
end
