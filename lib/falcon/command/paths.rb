# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2024, by Samuel Williams.

require_relative "../configuration"

module Falcon
	module Command
		# A helper for resolving wildcard configuration paths.
		module Paths
			# Resolve a set of `@paths` that may contain wildcards, into a sorted, unique array.
			# @returns [Array(String)]
			def resolved_paths(&block)
				if @paths
					@paths.collect do |path|
						Dir.glob(path)
					end.flatten.sort.uniq.each(&block)
				end
			end
			
			# Build a configuration based on the resolved paths.
			def configuration
				configuration = Configuration.new
				
				self.resolved_paths do |path|
					path = File.expand_path(path)
					
					configuration.load_file(path)
				end
				
				return configuration
			end
		end
	end
end
