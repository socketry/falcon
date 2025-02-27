# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2024, by Samuel Williams.

require_relative "../environment"

require "async/container/supervisor"

module Falcon
	module Environment
		# Provides an environment for hosting a supervisor which can monitor multiple applications.
		module Supervisor
			include Async::Container::Supervisor::Environment
			
			def monitors
				[Async::Container::Supervisor::MemoryMonitor.new(interval: 10)]
			end
		end
		
		LEGACY_ENVIRONMENTS[:supervisor] = Supervisor
	end
end
