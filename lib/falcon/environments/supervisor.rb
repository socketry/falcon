# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2020, by Samuel Williams.

require_relative '../service/supervisor'

# A application process monitor environment.
#
# @scope Falcon Environments
# @name supervisor
environment(:supervisor) do
	# The name of the supervisor
	# @attribute [String]
	name "supervisor"
	
	# The IPC path to use for communication with the supervisor.
	# @attribute [String]
	ipc_path do
		::File.expand_path("supervisor.ipc", root)
	end
	
	# The endpoint the supervisor will bind to.
	# @attribute [Async::IO::Endpoint]
	endpoint do
		Async::IO::Endpoint.unix(ipc_path)
	end
	
	# The service class to use for the supervisor.
	# @attribute [Class]
	service do
		::Falcon::Service::Supervisor
	end
end
