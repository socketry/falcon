# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024, by Samuel Williams.

module Falcon
	module Environment
		# This module provides a common interface for configuring the Falcon application.
		# @todo Reuse this for proxy and redirect services.
		module Configured
			# All the falcon application configuration paths.
			# @returns [Array(String)] Paths to the falcon application configuration files.
			def configuration_paths
				["/srv/http/*/falcon.rb"]
			end
			
			# All the falcon application configuration paths, with wildcards expanded.
			def resolved_configuration_paths
				configuration_paths.flat_map do |path|
					Dir.glob(path)
				end.uniq
			end
			
			def configuration
				::Async::Service::Configuration.load(resolved_configuration_paths)
			end
		end
	end
end
