# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2024, by Samuel Williams.

require 'async/http/client'
require 'protocol/http/headers'
require 'protocol/http/middleware'

require 'console/event/failure'
require 'traces/provider'

module Falcon
	module Middleware
		# A static middleware which always returns a 400 bad request response.
		module BadRequest
			def self.call(request)
				return Protocol::HTTP::Response[400, {}, []]
			end
			
			def self.close
			end
		end
		
		# A HTTP middleware for proxying requests to a given set of hosts.
		# Typically used for implementing virtual servers.
		class Proxy < Protocol::HTTP::Middleware
			FORWARDED = 'forwarded'
			X_FORWARDED_FOR = 'x-forwarded-for'
			X_FORWARDED_PROTO = 'x-forwarded-proto'
			
			VIA = 'via'
			CONNECTION = 'connection'
			
			# HTTP hop headers which *should* not be passed through the proxy.
			HOP_HEADERS = [
				'connection',
				'keep-alive',
				'public',
				'proxy-authenticate',
				'transfer-encoding',
				'upgrade',
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
				if authority = request.authority&.sub(/(\.)?(:\d+)?$/, '')
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
			# In particular, we set appropriate {VIA}, {FORWARDED}, {X_FORWARDED_FOR} and {X_FORWARDED_PROTO} headers.
			def prepare_request(request, host)
				forwarded = []
				
				Console.debug(self) do |buffer|
					buffer.puts "Request authority: #{request.authority}"
					buffer.puts "Host authority: #{host.authority}"
					buffer.puts "Request: #{request.method} #{request.path} #{request.version}"
					buffer.puts "Request headers: #{request.headers.inspect}"
				end
				
				# The authority of the request must match the authority of the endpoint we are proxying to, otherwise SNI and other things won't work correctly.
				request.authority = host.authority
				
				if address = request.remote_address
					request.headers.add(X_FORWARDED_FOR, address.ip_address)
					forwarded << "for=#{address.ip_address}"
				end
				
				if scheme = request.scheme
					request.headers.add(X_FORWARDED_PROTO, scheme)
					forwarded << "proto=#{scheme}"
				end
				
				unless forwarded.empty?
					request.headers.add(FORWARDED, forwarded.join(';'))
				end
				
				request.headers.add(VIA, "#{request.version} #{self.class}")
				
				self.prepare_headers(request.headers)
				
				return request
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
				return Protocol::HTTP::Response[502, {'content-type' => 'text/plain'}, [error.class.name]]
			end
			
			Traces::Provider(self) do
				def call(request)
					Traces.trace('falcon.middleware.proxy.call', attributes: {authority: request.authority}) do
						super
					end
				end
			end
		end
	end
end
