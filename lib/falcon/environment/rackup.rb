# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2026, by Samuel Williams.

require "rack/builder"
require_relative "../server"

module Falcon
	module Environment
		# Provides an environment for hosting loading a Rackup `config.ru` file.
		module Rackup
			# The path to the rackup configuration file.
			# @returns [String] The absolute path to the rackup file.
			def rackup_path
				File.expand_path("config.ru", root)
			end
			
			# Parse and load the rack application from the rackup file.
			# @returns [Protocol::Rack::Adapter] The parsed rack application.
			def rack_app
				::Protocol::Rack::Adapter.parse_file(rackup_path)
			end
			
			# Build the middleware stack for the rack application.
			# @returns [Protocol::HTTP::Middleware] The middleware stack.
			def middleware
				::Falcon::Server.middleware(rack_app, verbose: verbose, cache: cache)
			end
		end
	end
end
