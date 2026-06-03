# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2026, by Samuel Williams.
# Copyright, 2026, by Fletcher Dares.

require "async/http/client"
require "protocol/http/headers"
require "protocol/http/middleware"

require "console/event/failure"

module Falcon
	# @namespace
	module Middleware
		# A static middleware which always returns a 400 bad request response.
		module BadRequest
			# Handle a request by returning a 400 bad request response.
			# @parameter request [Protocol::HTTP::Request] The incoming request.
			# @returns [Protocol::HTTP::Response] A 400 bad request response.
			def self.call(request)
				return Protocol::HTTP::Response[400, {}, []]
			end
			
			# Close any resources used by this middleware.
			def self.close
			end
		end
		
		# A HTTP middleware for proxying requests to a given set of hosts.
		# Typically used for implementing virtual servers.
		class Proxy < Protocol::HTTP::Middleware
			FORWARDED = "forwarded"
			X_FORWARDED_FOR = "x-forwarded-for"
			X_FORWARDED_PROTO = "x-forwarded-proto"
			
			VIA = "via"
			CONNECTION = "connection"
			
			# Forwarding headers which carry trust-sensitive information about the
			# original client (their address and the request scheme). Because Falcon
			# acts as the trust boundary, any client-supplied values are untrustworthy,
			# so we strip every inbound forwarding header and author our own below from
			# connection-level facts.
			#
			# We emit both the modern RFC 7239 {FORWARDED} header and the legacy
			# `x-forwarded-for` / `x-forwarded-proto` headers, because many downstream
			# consumers still read the legacy ones. Notably Rack's
			# `Rack::Request#forwarded_for` (used by Rails' `ActionDispatch::RemoteIp`)
			# only prefers `Forwarded` and falls back to `X-Forwarded-For`; older Rack
			# (< 3) and a lot of application code read `X-Forwarded-For` directly.
			FORWARDING_HEADERS = [
				FORWARDED,
				X_FORWARDED_FOR,
				X_FORWARDED_PROTO,
				"x-forwarded-host",
				"x-forwarded-port",
			]
			
			# HTTP hop headers which *should* not be passed through the proxy.
			HOP_HEADERS = [
				"connection",
				"keep-alive",
				"public",
				"proxy-authenticate",
				"proxy-authorization",
				"transfer-encoding",
				"upgrade",
			]
			
			# Initialize the proxy middleware.
			# @parameter app [Protocol::HTTP::Middleware] The middleware to use if a request can't be proxied.
			# @parameter hosts [Hash(String, Service::Proxy)] The host applications to proxy to.
			def initialize(app, hosts)
				super(app)
				
				@server_context = nil
				
				@hosts = hosts
				@clients = {}
				
				@count = 0
			end
			
			# The number of requests that have been proxied.
			# @attribute [Integer]
			attr :count
			
			# Close all the connections to the upstream hosts.
			def close
				@clients.each_value(&:close)
				
				super
			end
			
			# Establish a connection to the specified upstream endpoint.
			# @parameter endpoint [Async::HTTP::Endpoint]
			def connect(endpoint)
				@clients[endpoint] ||= Async::HTTP::Client.new(endpoint)
			end
			
			# Lookup the appropriate host for the given request.
			# @parameter request [Protocol::HTTP::Request]
			# @returns [Service::Proxy]
			def lookup(request)
				# Trailing dot and port is ignored/normalized.
				if authority = request.authority&.sub(/(\.)?(:\d+)?$/, "")
					return @hosts[authority]
				end
			end
			
			# Prepare the headers to be sent to an upstream host.
			# In particular, we delete all connection and hop headers.
			def prepare_headers(headers)
				if connection = headers[CONNECTION]
					headers.extract(connection)
				end
				
				headers.extract(HOP_HEADERS)
			end
			
			# Prepare the request to be proxied to the specified host.
			#
			# Falcon acts as the trust boundary, so we strip any client-supplied
			# {FORWARDING_HEADERS} and author our own from connection-level facts: the
			# RFC 7239 {FORWARDED} header plus the legacy {X_FORWARDED_FOR} /
			# {X_FORWARDED_PROTO} headers, along with an appended {VIA} header. This
			# prevents a client from spoofing the forwarded address or scheme.
			def prepare_request(request, host)
				Console.debug(self) do |buffer|
					buffer.puts "Request authority: #{request.authority}"
					buffer.puts "Host authority: #{host.authority}"
					buffer.puts "Request: #{request.method} #{request.path} #{request.version}"
					buffer.puts "Request headers: #{request.headers.inspect}"
				end
				
				# The authority of the request must match the authority of the endpoint we are proxying to, otherwise SNI and other things won't work correctly.
				request.authority = host.authority
				
				# Discard any inbound forwarding headers so a client can't spoof them; we author our own below from connection-level facts.
				request.headers.extract(FORWARDING_HEADERS)
				
				forwarded = []
				
				if address = request.remote_address
					request.headers.add(X_FORWARDED_FOR, address.ip_address)
					forwarded << "for=#{forwarded_node(address)}"
				end
				
				if scheme = request.scheme
					request.headers.add(X_FORWARDED_PROTO, scheme)
					forwarded << "proto=#{scheme}"
				end
				
				unless forwarded.empty?
					request.headers.add(FORWARDED, forwarded.join(";"))
				end
				
				request.headers.add(VIA, "#{request.version} #{self.class}")
				
				self.prepare_headers(request.headers)
				
				return request
			end
			
			# Format a remote address as an RFC 7239 `for=` node identifier.
			# IPv6 addresses must be enclosed in square brackets and quoted.
			# @parameter address [Addrinfo] The remote address of the client.
			# @returns [String] The node identifier for use in a {FORWARDED} header.
			def forwarded_node(address)
				if address.ipv6?
					"\"[#{address.ip_address}]\""
				else
					address.ip_address
				end
			end
			
			# Proxy the request if the authority matches a specific host.
			# @parameter request [Protocol::HTTP::Request]
			def call(request)
				if host = lookup(request)
					@count += 1
					
					request = self.prepare_request(request, host)
					
					client = connect(host.endpoint)
					
					client.call(request)
				else
					super
				end
			rescue => error
				Console::Event::Failure.for(error).emit(self)
				return Protocol::HTTP::Response[502, {"content-type" => "text/plain"}, [error.class.name]]
			end
			
		end
	end
end
