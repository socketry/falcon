# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2026, by Samuel Williams.

require "async/http/server"

require "protocol/http/middleware/builder"
require "protocol/http/content_encoding"

require "async/http/cache"
require "async/utilization"
require_relative "body/request_finished"
require_relative "middleware/verbose"
require "protocol/rack"

module Falcon
	# A server listening on a specific endpoint, hosting a specific middleware.
	class Server < Async::HTTP::Server
		# Wrap a rack application into a middleware suitable the server.
		# @parameter rack_app [Proc | Object] A rack application/middleware.
		# @parameter verbose [Boolean] Whether to add the {Middleware::Verbose} middleware.
		# @parameter cache [Boolean] Whether to add the {Async::HTTP::Cache} middleware.
		def self.middleware(rack_app, verbose: false, cache: true)
			::Protocol::HTTP::Middleware.build do
				if verbose
					use Middleware::Verbose
				end
				
				if cache
					use Async::HTTP::Cache::General
				end
				
				use ::Protocol::HTTP::ContentEncoding
				
				use ::Protocol::Rack::Adapter
				run rack_app
			end
		end
		
		# Initialize the server and set up statistics tracking.
		#
		# @parameter utilization_registry [Registry, nil] The utilization registry to use for metrics tracking.
		#   If nil, a new registry instance is created.
		def initialize(*arguments, utilization_registry: nil, **options)
			super(*arguments, **options)
			
			utilization_registry ||= Async::Utilization::Registry.new
			
			# Get metric references for utilization tracking:
			@connections_total_metric = utilization_registry.metric(:connections_total)
			@connections_active_metric = utilization_registry.metric(:connections_active)
			@requests_total_metric = utilization_registry.metric(:requests_total)
			@requests_active_metric = utilization_registry.metric(:requests_active)
		end
		
		# Accept a new connection and track connection statistics.
		def accept(...)
			@connections_total_metric.increment
			@connections_active_metric.track do
				super
			end
		end
		
		# Handle a request and track request statistics.
		#
		# Uses manual increment/decrement so requests_active stays elevated until the
		# response body is closed (including rack.response_finished). The
		# Body::RequestFinished wrapper runs the decrement after the body closes,
		# so response_finished callbacks are counted as active.
		def call(...)
			@requests_total_metric.increment
			@requests_active_metric.increment
			
			return Body::RequestFinished.wrap(super, @requests_active_metric)
		end
		
		# Generates a human-readable string representing the current statistics.
		#
		# e.g. `C=23/3.42K R=2/3.42K L=0.273`
		#
		# This can be interpreted as:
		#
		# - `C=23/3.42K` - The number of connections currently open and the total number of connections accepted.
		# - `R=2/3.42K` - The number of requests currently being processed and the total number of requests received.
		# - `L=0.273` - The average scheduler load of the server, where 0.0 is idle and 1.0 is fully loaded.
		#
		# @returns [String] A string representing the current statistics.
		def statistics_string
			"C=#{format_count @connections_active_metric.value}/#{format_count @connections_total_metric.value} R=#{format_count @requests_active_metric.value}/#{format_count @requests_total_metric.value}"
		end
		
		private
		
		def format_count(value)
			if value > 1_000_000
				"#{(value/1_000_000.0).round(2)}M"
			elsif value > 1_000
				"#{(value/1_000.0).round(2)}K"
			else
				value
			end
		end
	end
end
