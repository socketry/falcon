# frozen_string_literal: true

module Falcon
	class Railtie < Rails::Railtie
		config.active_support.isolation_level = :fiber
	end
end
