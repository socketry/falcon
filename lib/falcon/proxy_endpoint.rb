# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2026, by Samuel Williams.

require "io/endpoint/unix_endpoint"

module Falcon
	# An endpoint suitable for proxing requests, typically via a unix pipe.
	class ProxyEndpoint < ::IO::Endpoint::Generic
		# Initialize the proxy endpoint.
		# @parameter endpoint [::IO::Endpoint::Generic] The endpoint which will be used for connecting/binding.
		def initialize(endpoint, **options)
			super(**options)
			
			@endpoint = endpoint
		end
		
		# Generate a string representation of the proxy endpoint.
		# @returns [String] A string representation including protocol and endpoint.
		def to_s
			"\#<#{self.class} protocol=#{self.protocol} endpoint=#{@endpoint}>"
		end
		
		# The actual endpoint for I/O.
		# @attribute [::IO::Endpoint::Generic]
		attr :endpoint
		
		# The protocol to use for this connection.
		# @returns [Async::HTTP::Protocol] A specific protocol, e.g. {Async::HTTP::Protocol::HTTP1}
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
		
		# The default file mode applied to bound unix sockets: readable and writable by the owner only.
		#
		# Connecting to a unix socket requires write permission on the socket file, so this permits only the owner (and root, which ignores mode bits) to connect. The topologies supported by `falcon virtual` run the proxy either as root or as the same user as the application, so neither requires group access.
		DEFAULT_MODE = 0o600
		
		# The file mode to apply to bound unix sockets.
		#
		# The proxy forwards client details (e.g. `x-forwarded-for`) to the application via this endpoint, and the application trusts those headers. Restricting the socket's permissions prevents other local users from connecting directly and forging them.
		#
		# Use `0o660` to allow a separate front-end proxy running in the application's group to connect, or `nil` to leave the permissions as determined by the process umask.
		#
		# @returns [Integer | Nil] The file mode, or `nil` (or `false`) to leave the permissions as determined by the process umask.
		def mode
			@options.fetch(:mode, DEFAULT_MODE)
		end
		
		# Connect to the endpoint.
		def connect(&block)
			@endpoint.connect(&block)
		end
		
		# Bind to the endpoint, restricting the permissions of any unix socket files that were created.
		# @parameter wrapper [::IO::Endpoint::Wrapper] The wrapper to use for binding, as passed by {::IO::Endpoint::Generic#accept}.
		# @yields {|socket| ...} If a block is given, yields each bound socket after its permissions have been restricted.
		# 	@parameter socket [Socket] The bound socket.
		# @returns [Array(Socket)] The bound sockets.
		def bind(wrapper = self.wrapper, &block)
			if block_given?
				@endpoint.bind(wrapper) do |socket|
					restrict_permissions!(socket)
					yield socket
				end
			else
				@endpoint.bind(wrapper).each do |socket|
					restrict_permissions!(socket)
				end
			end
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
		
		# Apply {#mode} to the socket file backing the given socket, if it is a named unix socket.
		#
		# The socket file is created by `bind(2)` with permissions of `0777 & ~umask`, and connecting requires write permission on it. Under the common `022` umask that already limits connections to the owner, but a permissive umask (`002` or `000`) leaves the socket connectable by the group or by everyone. We restrict the permissions immediately after binding, before the socket is handed over for accepting connections. There is a brief window between `bind` and `chmod` in which a local user could connect; a fully race-free approach would require setting the umask around `bind`, but the umask is process-wide and that would affect unrelated files created concurrently.
		#
		# @parameter socket [Socket] The bound socket.
		private def restrict_permissions!(socket)
			return unless mode = self.mode
			
			local_address = socket.local_address
			return unless local_address.unix?
			
			path = local_address.unix_path
			
			# Unnamed and abstract (Linux) unix sockets have no file to restrict:
			return if path.empty? or path.start_with?("\0")
			
			::File.chmod(mode, path)
		end
	end
end
