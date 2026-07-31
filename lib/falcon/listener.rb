# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

module Falcon
	# Describes a bound listener for a Falcon server.
	class Listener
		# Initialize a bound listener.
		# @parameter name [String] The logical listener name.
		# @parameter scheme [String] The application protocol scheme.
		# @parameter protocols [Array(String)] The supported application protocol names.
		# @parameter endpoint [IO::Endpoint::BoundEndpoint] The bound endpoint.
		def initialize(name:, scheme:, protocols:, endpoint:)
			@name = name
			@scheme = scheme
			@protocols = protocols.map(&:to_s).freeze
			@endpoint = endpoint
			@addresses = endpoint.sockets.map{|socket| socket.to_io.local_address}.freeze
			freeze
		end
		
		# @attribute [String] The logical listener name.
		attr_reader :name
		
		# @attribute [String] The application protocol scheme.
		attr_reader :scheme
		
		# @attribute [Array(String)] The supported application protocol names.
		attr_reader :protocols
		
		# @attribute [IO::Endpoint::BoundEndpoint] The bound endpoint.
		attr_reader :endpoint
		
		# @attribute [Array(Addrinfo)] The bound addresses.
		attr_reader :addresses
		
		# Close the bound endpoint.
		def close
			@endpoint.close
		end
	end
end
