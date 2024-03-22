# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2023, by Samuel Williams.

require 'rack/builder'
require_relative '../server'
require_relative '../environments'

module Falcon
	module Environment
		module Rack
			def rackup_path
				'config.ru'
			end
			
			def rack_app
				::Rack::Builder.parse_file(rackup_path)
			end
			
			def middleware
				::Falcon::Server.middleware(rack_app, verbose: verbose, cache: cache)
			end
		end
		
		LEGACY_ENVIRONMENTS[:rack] = Rack
	end
end
