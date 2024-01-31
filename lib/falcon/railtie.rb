# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024, by Samuel Williams.

module Falcon
	class Railtie < Rails::Railtie
		config.active_support.isolation_level = :fiber
	end
end
