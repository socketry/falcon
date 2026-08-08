# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "protocol/http/middleware/builder"
require "protocol/rack"

require_relative "../server"

module Falcon
	module Environment
		# Provides configuration discovery and loading for `falcon serve`.
		module Serve
			# Discover the application configuration path.
			# @returns [String] The absolute application configuration path.
			def configuration_path
				serve_path = File.expand_path("config/serve.rb", root)
				if File.file?(serve_path)
					return serve_path
				end
				
				rackup_path = File.expand_path("config.ru", root)
				if File.file?(rackup_path)
					return rackup_path
				end
				
				raise ArgumentError, "Could not find config/serve.rb or config.ru in #{root}!"
			end
			
			# Load and wrap the configured application.
			# @returns [Protocol::HTTP::Middleware] The middleware stack.
			def middleware
				path = configuration_path
				
				case File.extname(path)
				when ".rb"
					application = ::Protocol::HTTP::Middleware.load(path)
					return ::Falcon::Server.protocol_middleware(application, verbose: verbose, cache: cache)
				when ".ru"
					application = ::Protocol::Rack::Adapter.parse_file(path)
					return ::Falcon::Server.middleware(application, verbose: verbose, cache: cache)
				else
					raise ArgumentError, "Unsupported application configuration: #{path}!"
				end
			end
		end
	end
end
