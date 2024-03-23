# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2024, by Samuel Williams.

require_relative '../service/supervisor'
require_relative '../environment'

module Falcon
	module Environment
		# Provides an environment for hosting a supervisor which can monitor multiple applications.
		module Supervisor
			# The name of the supervisor
			# @returns [String]
			def name
				"supervisor"
			end
			
			# The IPC path to use for communication with the supervisor.
			# @returns [String]
			def ipc_path
				::File.expand_path("supervisor.ipc", root)
			end
			
			# The endpoint the supervisor will bind to.
			# @returns [Async::IO::Endpoint]
			def endpoint
				Async::IO::Endpoint.unix(ipc_path)
			end
			
			# The service class to use for the supervisor.
			# @returns [Class]
			def service_class
				::Falcon::Service::Supervisor
			end
		end
		
		LEGACY_ENVIRONMENTS[:supervisor] = Supervisor
	end
end
