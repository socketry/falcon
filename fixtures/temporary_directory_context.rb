# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024, by Samuel Williams.

require "tmpdir"

module TemporaryDirectoryContext
	def around(&block)
		Dir.mktmpdir do |root|
			@root = root
			super(&block)
			@root = nil
		end
	end
	
	attr :root
end
