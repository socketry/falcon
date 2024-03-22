# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2023, by Samuel Williams.

require_relative '../service/application'
require_relative 'rackup'

module Falcon
	module Environments
		module Rack
			include Service::Application::Environment
			include Rackup
		end
		
		LEGACY_ENVIRONMENTS[:rack] = Rack
	end
end
