# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require_relative "server"

module Falcon
	# @namespace
	module Service
		# A managed service for running Falcon workers with independently bound endpoints.
		class Cluster < Server
			# Cluster workers bind independently in their own process.
			def bind_endpoint
			end
			
			# Bind and yield a listener owned by a cluster worker.
			# @parameter evaluator [Environment::Evaluator] The environment evaluator.
			# @yields {|listener| ...} The listener owned by the worker.
			# 	@parameter listener [Falcon::Listener] The bound listener.
			def with_listener(evaluator)
				endpoint = evaluator.endpoint
				bound_endpoint = endpoint.bound
				listener = make_listener(evaluator, endpoint, bound_endpoint)
				
				yield listener
			ensure
				bound_endpoint&.close
			end
		end
	end
end
