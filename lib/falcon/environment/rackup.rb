# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024, by Samuel Williams.

require 'rack/builder'
require_relative '../server'

module Falcon
	module Environment
		# Provides an environment for hosting loading a Rackup `config.ru` file.
		module Rackup
			def rackup_path
				'config.ru'
			end
			
			if Gem::Version.new(Rack::RELEASE) < Gem::Version.new("3")
				def rack_app
					::Rack::Builder.parse_file(rackup_path).first
				end
			else
				def rack_app
					::Rack::Builder.parse_file(rackup_path)
				end
			end
			
			def middleware
				::Falcon::Server.middleware(rack_app, verbose: verbose, cache: cache)
			end
		end
	end
end
