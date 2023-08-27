# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2023, by Samuel Williams.

require_relative 'service/generic'

module Falcon
	# Represents one or more services associated with a host.
	#
	# The services model allows falcon to manage one more more service associated with a given host. Some examples of services include:
	#
	# - Rack applications wrapped by {Service::Application}.
	# - Host supervisor implemented in {Service::Supervisor}.
	# - Proxy services wrapped by {Service::Proxy}.
	#
	# The list of services is typically generated from the user supplied `falcon.rb` configuration file, which is loaded into an immutable {Configuration} instance, which is mapped into a list of services.
	class Services
		# Initialize the services from the given configuration.
		#
		# @parameter configuration [Configuration]
		def initialize(configuration)
			@named = {}
			
			configuration.each(:service) do |environment|
				service = Service::Generic.wrap(environment)
				
				add(service)
			end
		end
		
		# Enumerate all named services.
		def each(&block)
			@named.each_value(&block)
		end
		
		# Add a named service.
		#
		# @parameter service [Service]
		def add(service)
			@named[service.name] = service
		end
		
		# Start all named services.
		def start
			@named.each do |name, service|
				Console.logger.debug(self) {"Starting #{name}..."}
				service.start
			end
		end
		
		# Setup all named services into the given container.
		#
		# @parameter container [Async::Container::Generic]
		def setup(container)
			@named.each do |name, service|
				Console.logger.debug(self) {"Setup #{name} into #{container}..."}
				service.setup(container)
			end
			
			return container
		end
		
		# Stop all named services.
		def stop
			failed = false
			
			@named.each do |name, service|
				Console.logger.debug(self) {"Stopping #{name}..."}
				
				begin
					service.stop
				rescue => error
					failed = true
					Console.logger.error(self, error)
				end
			end
			
			return failed
		end
	end
end
