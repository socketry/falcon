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

require_relative 'proxy'

require 'async/http/endpoint'
require 'async/io/shared_endpoint'

module Falcon
	module Service
		# Implements an application server using an internal clear-text proxy.
		class Application < Proxy
			def initialize(environment)
				super
				
				@bound_endpoint = nil
			end
			
			# The middleware that will be served by this application.
			# @returns [Protocol::HTTP::Middleware]
			def middleware
				# In a multi-threaded container, we don't want to modify the shared evaluator's cache, so we create a new evaluator:
				@environment.evaluator.middleware
			end
			
			# Number of instances to start.
			# @returns [Integer | nil]
			def count
			  @environment.evaluator.count
			end
			
			# Preload any resources specified by the environment.
			def preload!
				if scripts = @evaluator.preload
					scripts.each do |path|
						Console.logger.info(self) {"Preloading #{path}..."}
						full_path = File.expand_path(path, self.root)
						load(full_path)
					end
				end
			end
			
			# Prepare the bound endpoint for the application instances.
			# Invoke {preload!} to load shared resources into the parent process.
			def start
				Console.logger.info(self) {"Binding to #{self.endpoint}..."}
				
				@bound_endpoint = Async::Reactor.run do
					Async::IO::SharedEndpoint.bound(self.endpoint)
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
