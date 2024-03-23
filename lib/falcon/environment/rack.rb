# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2024, by Samuel Williams.

require_relative 'application'
require_relative 'rackup'
require_relative '../environment'

module Falcon
	module Environment
		module Rack
			include Application
			include Rackup
		end
		
		LEGACY_ENVIRONMENTS[:rack] = Rack
	end
end
