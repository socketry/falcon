# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2024, by Samuel Williams.

require 'io/endpoint/unix_endpoint'

module Falcon
	# An endpoint suitable for proxing requests, typically via a unix pipe.
	class ProxyEndpoint < ::IO::Endpoint::Generic
		# Initialize the proxy endpoint.
		# @parameter endpoint [::IO::Endpoint::Generic] The endpoint which will be used for connecting/binding.
		def initialize(endpoint, **options)
			super(**options)
			
			@endpoint = endpoint
		end
		
		def to_s
			"\#<#{self.class} endpoint=#{@endpoint}>"
		end
		
		# The actual endpoint for I/O.
		# @attribute [::IO::Endpoint::Generic]
		attr :endpoint
		
		# The protocol to use for this connection.
		# @returns [Async::HTTP::Protocol] A specific protocol, e.g. {Async::HTTP::P}
		def protocol
			@options[:protocol]
		end
		
		# The scheme to use for this endpoint.
		# e.g. `"http"`.
		# @returns [String]
		def scheme
			@options[:scheme]
		end
		
		# The authority to use for this endpoint.
		# e.g. `"myapp.com"`.
		# @returns [String]
		def authority
			@options[:authority]
		end
		
		# Connect to the endpoint.
		def connect(&block)
			@endpoint.connect(&block)
		end
		
		# Bind to the endpoint.
		def bind(&block)
			@endpoint.bind(&block)
		end
		
		# Enumerate the endpoint.
		# If the endpoint has multiple underlying endpoints, this will enumerate them individually.
		# @yields {|endpoint| ...}
		# 	@parameter endpoint [ProxyEndpoint]
		def each
			return to_enum unless block_given?
			
			@endpoint.each do |endpoint|
				yield self.class.new(endpoint, **@options)
			end
		end
		
		# Create a proxy unix endpoint with the specific path.
		# @returns [ProxyEndpoint]
		def self.unix(path, **options)
			self.new(::IO::Endpoint.unix(path), **options)
		end
	end
end
