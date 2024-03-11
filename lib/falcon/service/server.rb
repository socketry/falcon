# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2023, by Samuel Williams.

require 'async/service/generic'
require 'async/http/endpoint'

require_relative '../server'

module Falcon
	module Service
		class Server < Async::Service::Generic
			module Environment
				# Options to use when creating the container.
				def container_options
					{restart: true}
				end
				
				# The host that this proxy will receive connections for.
				def url
					"http://[::]:9292"
				end
				
				# The upstream endpoint that will handle incoming requests.
				# @attribute [Async::HTTP::Endpoint]
				def endpoint
					::Async::HTTP::Endpoint.parse(url)
				end
				
				# The service class to use for the proxy.
				# @attribute [Class]
				def service_class
					::Falcon::Service::Server
				end
				
				def rackup_path
					'config.ru'
				end
				
				def rack_app
					Rack::Builder.parse_file(rackup_path)
				end
				
				def verbose
					false
				end
				
				def cache
					false
				end
				
				def middleware
					Falcon::Server.middleware(rack_app, verbose: verbose, cache: cache)
				end
			end
			
			def self.included(target)
				target.include(Environment)
			end
			
			def initialize(...)
				super
				
				@endpoint = nil
				@bound_endpoint = nil
			end
			
			# Prepare the bound endpoint for the server.
			def start
				@endpoint ||= @evaluator.endpoint
				
				Sync do
					@bound_endpoint = @endpoint.bound
				end
				
				Console.logger.info(self) {"Starting #{name} on #{@endpoint.to_url}"}
				
				super
			end
			
			# Setup the container with the application instance.
			# @parameter container [Async::Container::Generic]
			def setup(container)
				container_options = @evaluator.container_options
				
				container.run(name: self.name, restart: true, **container_options) do |instance|
					evaluator = @environment.evaluator
					
					Async do |task|
						server = Falcon::Server.new(evaluator.middleware, @bound_endpoint, protocol: @endpoint.protocol, scheme: @endpoint.scheme)
						
						server.run
						
						instance.ready!
						
						task.children.each(&:wait)
					end
				end
			end
			
			# Close the bound endpoint.
			def stop(...)
				if @bound_endpoint
					@bound_endpoint.close
					@bound_endpoint = nil
				end
				
				@endpoint = nil
				
				super
			end
		end
	end
end
