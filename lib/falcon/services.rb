# frozen_string_literal: true

# Copyright, 2018, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

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
