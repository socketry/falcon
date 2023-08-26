# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2020, by Samuel Williams.
# Copyright, 2018, by Mitsutaka Mimura.

require_relative 'command/top'

module Falcon
	module Command
		# The main entry point for the `falcon` executable.
		# @parameter arguments [Array(String)] The command line arguments.
		def self.call(*arguments)
			Top.call(*arguments)
		end
	end
end
