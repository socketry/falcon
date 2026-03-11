# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

require "protocol/http/body/wrapper"

module Falcon
	# @namespace
	module Body
		# Wraps a response body and decrements a metric after the body is closed.
		#
		# Runs close on the underlying body first (which invokes rack.response_finished),
		# then decrements the metric. Use this so requests_active stays elevated until
		# the request is fully finished (including response_finished callbacks).
		class RequestFinished < Protocol::HTTP::Body::Wrapper
			# Wrap a response body with a metric. If the body is nil or empty, decrements immediately.
			#
			# @parameter message [Protocol::HTTP::Response] The response whose body to wrap.
			# @parameter metric [Async::Utilization::Metric] The metric to decrement when the body is closed.
			# @returns [Protocol::HTTP::Response] The message (modified in place).
			def self.wrap(message, metric)
				if body = message&.body and !body.empty?
					message.body = new(body, metric)
				else
					metric.decrement
				end
				
				message
			end
			
			# @parameter body [Protocol::HTTP::Body::Readable] The body to wrap.
			# @parameter metric [Async::Utilization::Metric] The metric to decrement on close.
			def initialize(body, metric)
				super(body)
				
				@metric = metric
			end
			
			# @returns [Boolean] False, the wrapper does not support rewinding.
			def rewindable?
				false
			end
			
			# @returns [Boolean] False, rewinding is not supported.
			def rewind
				false
			end
			
			# Closes the underlying body (invoking rack.response_finished), then decrements the metric.
			#
			# @parameter error [Exception, nil] Optional error that caused the close.
			def close(error = nil)
				super
				
				@metric&.decrement
				@metric = nil
			end
		end
	end
end
