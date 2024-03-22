# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2023, by Samuel Williams.
# Copyright, 2020, by Daniel Evans.

require_relative 'proxy'
require_relative '../proxy_endpoint'

require 'async/http/endpoint'
require 'async/io/shared_endpoint'

module Falcon
	module Service
		# Implements an application server using an internal clear-text proxy.
		class Application < Server
			module Environment
				include Server::Environment
				
				# The service class to use for the application.
				# @returns [Class]
				def service_class
					::Falcon::Service::Application
				end
				
				# The middleware stack for the application.
				# @returns [Protocol::HTTP::Middleware]
				def middleware
					::Protocol::HTTP::Middleware::HelloWorld
				end
				
				# The scheme to use to communicate with the application.
				# @returns [String]
				def scheme
					'https'
				end
				
				# The protocol to use to communicate with the application.
				#
				# Typically one of {Async::HTTP::Protocol::HTTP1} or {Async::HTTP::Protocl::HTTP2}.
				#
				# @returns [Async::HTTP::Protocol]
				def protocol
					Async::HTTP::Protocol::HTTP2
				end
				
				# The IPC path to use for communication with the application.
				# @returns [String]
				def ipc_path
					::File.expand_path("application.ipc", root)
				end
				
				# The endpoint that will be used for communicating with the application server.
				# @returns [Async::IO::Endpoint]
				def endpoint
					::Falcon::ProxyEndpoint.unix(ipc_path,
						protocol: protocol,
						scheme: scheme,
						authority: authority
					)
				end
				
				# Number of instances to start.
				# @returns [Integer | nil]
				def count
					nil
				end
			end
			
			def initialize(...)
				super
				
				@bound_endpoint = nil
			end
			
			# Prepare the bound endpoint for the application instances.
			# Invoke {preload!} to load shared resources into the parent process.
			def start
				endpoint = @evaluator.endpoint
				
				Console.logger.info(self) {"Binding to #{endpoint}..."}
				
				@bound_endpoint = Async::Reactor.run do
					Async::IO::SharedEndpoint.bound(endpoint)
				end.wait
				
				preload!
				
				super
			end
			
			# Setup instances of the application into the container.
			# @parameter container [Async::Container::Generic]
			def setup(container)
				protocol = self.protocol
				scheme = self.scheme
				
				run_options = {
					name: self.name,
					restart: true,
				}
				
				run_options[:count] = count unless count.nil?
				
				container.run(**run_options) do |instance|
					Async do |task|
						Console.logger.info(self) {"Starting application server for #{self.root}..."}
						
						server = Server.new(self.middleware, @bound_endpoint, protocol: protocol, scheme: scheme)
						
						server.run
						
						instance.ready!
						
						task.children.each(&:wait)
					end
				end
				
				super
			end
			
			# Close the bound endpoint.
			def stop
				@bound_endpoint&.close
				@bound_endpoint = nil
				
				super
			end
		end
	end
end
