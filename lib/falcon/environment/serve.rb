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
			# The explicitly specified application configuration path, if any.
			# @returns [String | Nil]
			def configuration_path
				nil
			end
			
			# Resolve the application configuration path.
			# @returns [String] The absolute application configuration path.
			def resolved_configuration_path
				if configuration_path
					return File.expand_path(configuration_path, root)
				end
				
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
				path = resolved_configuration_path
				
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
