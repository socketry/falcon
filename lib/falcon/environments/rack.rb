# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2023, by Samuel Williams.

require_relative '../service/rackup'
require_relative '../environments'

module Falcon
	module Environments
		LEGACY_ENVIRONMENTS[:rack] = Service::Rackup::Environment
	end
end
