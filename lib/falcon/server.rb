# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2025, by Samuel Williams.

require "async/http/server"

require "protocol/http/middleware/builder"
require "protocol/http/content_encoding"

require "async/http/cache"
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
		
		def initialize(...)
			super
			
			@accept_count = 0
			@connection_count = 0
			
			@request_count = 0
			@active_count = 0
		end
		
		attr :request_count
		attr :accept_count
		attr :connect_count
		
		def accept(...)
			@accept_count += 1
			@connection_count += 1
			
			super
		ensure
			@connection_count -= 1
		end
		
		def call(...)
			@request_count += 1
			@active_count += 1
			
			super
		ensure
			@active_count -= 1
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
			"C=#{format_count @connection_count}/#{format_count @accept_count} R=#{format_count @active_count}/#{format_count @request_count}"
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
