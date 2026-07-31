# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require_relative "server"
require_relative "../service/cluster"

module Falcon
	module Environment
		# Provides an environment for hosting a cluster of Falcon server workers, where each worker binds its own endpoint.
		module Cluster
			include Server
			
			# The service class to use for the cluster.
			# @returns [Class]
			def service_class
				Service::Cluster
			end
			
			# The host that this server will receive connections for.
			def url
				"http://[::]:0"
			end
			
		end
	end
end
