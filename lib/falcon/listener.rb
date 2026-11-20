# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "io/endpoint/bound_endpoint"

module Falcon
	# Describes a bound listener for a Falcon server.
	class Listener
		# A bound endpoint whose sockets are shared by the workers of a service.
		class Endpoint < ::IO::Endpoint::BoundEndpoint
			# Bind the endpoint using the given wrapper. Once a socket stops listening, see {Listener#shutdown}, its accept loop waits to be stopped, as it does while no connections arrive.
			# @parameter wrapper [::IO::Endpoint::Wrapper] The wrapper to use for binding.
			# @yields {|socket| ...} If a block is given, yields each bound socket.
			# 	@parameter socket [Socket] A bound socket.
			# @returns [Array(Socket)] An array of bound sockets.
			def bind(wrapper = self.wrapper, &block)
				return super unless block_given?
				
				super do |server|
					yield server
				rescue Errno::EINVAL
					raise if listening?(server)
					
					sleep
				end
			end
			
			private
			
			def listening?(server)
				server.to_io.getsockopt(::Socket::SOL_SOCKET, ::Socket::SO_ACCEPTCONN).bool
			end
		end
		
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
		
		# Stop listening on the bound TCP sockets, in every process that shares them. New connections are refused, and established connections are unaffected.
		#
		# Closing the endpoint is not enough when forked workers hold their own descriptors for its sockets. Only Linux stops a socket listening when it is shut down, and only for TCP: a UNIX socket refuses connections but stays readable, so its accept loops would spin. Other sockets keep listening until every descriptor is closed.
		def shutdown
			return unless RUBY_PLATFORM.include?("linux")
			
			@endpoint.sockets.each do |socket|
				io = socket.to_io
				
				io.shutdown(::Socket::SHUT_RD) if io.local_address.ip?
			end
		end
		
		# Close the bound endpoint.
		def close
			@endpoint.close
		end
	end
end
