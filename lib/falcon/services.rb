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
	class Services
		def initialize(configuration)
			@named = {}
			
			configuration.each(:service) do |environment|
				service = Service::Generic.wrap(environment)
				
				add(service)
			end
		end
		
		def each(&block)
			@named.each_value(&block)
		end
		
		def add(service)
			@named[service.name] = service
		end
		
		def start
			@named.each do |name, service|
				Async.logger.debug(self) {"Starting #{name}..."}
				service.start
			end
		end
		
		def setup(container)
			@named.each do |name, service|
				Async.logger.debug(self) {"Setup #{name} into #{container}..."}
				service.setup(container)
			end
			
			return container
		end
		
		def stop
			failed = false
			
			@named.each do |name, service|
				Async.logger.debug(self) {"Stopping #{name}..."}
				
				begin
					service.stop
				rescue
					failed = true
					Async.logger.error(self, $!)
				end
			end
			
			return failed
		end
	end
end
