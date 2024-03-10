# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2023, by Samuel Williams.

require_relative 'application'
require_relative '../environments'

module Falcon
	module Environments
		# A rack application environment.
		module Rack
			include Application
			
			# The rack configuration path e.g. `config.ru`.
			# @returns [String]
			def config_path
				::File.expand_path("config.ru", root)
			end
			
			# Whether to enable the application layer cache.
			# @returns [String]
			def cache
				false
			end
			
			def verbose
				false
			end
			
			# The middleware stack for the rack application.
			# @returns [Protocol::HTTP::Middleware]
			def middleware
				app, _ = ::Rack::Builder.parse_file(config_path)
				
				::Falcon::Server.middleware(app,
					verbose: verbose,
					cache: cache
				)
			end
		end
		
		LEGACY_ENVIRONMENTS[:rack] = Rack
	end
end
