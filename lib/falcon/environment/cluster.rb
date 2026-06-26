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
			
			# The endpoint bound by the current worker.
			# @returns [IO::Endpoint::BoundEndpoint | Nil]
			def bound_endpoint
				@bound_endpoint
			end
			
			# Set the endpoint bound by the current worker.
			# @parameter bound_endpoint [IO::Endpoint::BoundEndpoint]
			def bound_endpoint=(bound_endpoint)
				@bound_endpoint = bound_endpoint
			end
			
			# The first socket address bound by the current worker.
			# @returns [Addrinfo | Nil]
			def bound_address
				@bound_endpoint&.sockets&.first&.to_io&.local_address
			end
			
			# The port bound by the current worker.
			# @returns [Integer | Nil]
			def bound_port
				bound_address&.ip_port
			end
		end
	end
end
