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
			
			# Prepare a cluster worker after its endpoint has been bound.
			#
			# @parameter instance [Object] The container instance.
			# @parameter listener [Service::Cluster::Listener] The worker's bound listener.
			def prepare_worker!(instance, listener:)
				prepare!(instance)
			end
		end
	end
end
