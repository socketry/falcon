# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2025, by Samuel Williams.

require "async/http/server"

require "protocol/http/middleware/builder"
require "protocol/http/content_encoding"

require "async/http/cache"
require_relative "middleware/verbose"
require_relative "middleware/validate"
require "protocol/rack"

module Falcon
	# A server listening on a specific endpoint, hosting a specific middleware.
	class Server < Async::HTTP::Server
		# Wrap a rack application into a middleware suitable the server.
		# @parameter rack_app [Proc | Object] A rack application/middleware.
		# @parameter validate [Boolean] Whether to add the {Middleware::Validate} middleware.
		# @parameter verbose [Boolean] Whether to add the {Middleware::Verbose} middleware.
		# @parameter cache [Boolean] Whether to add the {Async::HTTP::Cache} middleware.
		def self.middleware(rack_app, verbose: false, validate: true, cache: true)
			::Protocol::HTTP::Middleware.build do
				if verbose
					use Middleware::Verbose
				end
				
				if validate
					use Middleware::Validate
				end
				
				if cache
					use Async::HTTP::Cache::General
				end
				
				use ::Protocol::HTTP::ContentEncoding
				
				use ::Protocol::Rack::Adapter
				run rack_app
			end
		end
	end
end
