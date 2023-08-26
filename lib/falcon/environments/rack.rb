# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2020, by Samuel Williams.

load :application

# A rack application environment.
#
# Derived from {.application}.
#
# @scope Falcon Environments
# @name rack
environment(:rack, :application) do
	# The rack configuration path.
	# @attribute [String]
	config_path {::File.expand_path("config.ru", root)}
	
	# Whether to enable the application layer cache.
	# @attribute [String]
	cache false
	
	# The middleware stack for the rack application.
	# @attribute [Protocol::HTTP::Middleware]
	middleware do
		app, _ = ::Rack::Builder.parse_file(config_path)
		
		::Falcon::Server.middleware(app,
			verbose: verbose,
			cache: cache
		)
	end
end
