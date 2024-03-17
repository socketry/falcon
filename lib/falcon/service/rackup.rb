# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024, by Samuel Williams.

require_relative 'server'

module Falcon
	module Service
		# A controller for redirecting requests.
		class Rackup < Server
			module Environment
				include Server::Environment
				
				def rackup_path
					'config.ru'
				end
				
				def rack_app
					Rack::Builder.parse_file(rackup_path)
				end
				
				def middleware
					Falcon::Server.middleware(rack_app, verbose: verbose, cache: cache)
				end
			end
		end
	end
end
