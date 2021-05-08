# frozen_string_literal: true

# Copyright, 201, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

module Falcon
	module Service
		# Captures the stateful behaviour of a specific service.
		# Specifies the interfaces required by derived classes.
		#
		# Designed to be invoked within an {Async::Controller::Container}.
		class Generic
			# Convert the given environment into a service if possible.
			# @parameter environment [Build::Environment] The environment to use to construct the service.
			def self.wrap(environment)
				evaluator = environment.evaluator
				service = evaluator.service || self
				
				return service.new(environment)
			end
			
			# Initialize the service from the given environment.
			# @parameter environment [Build::Environment]
			def initialize(environment)
				@environment = environment
				@evaluator = @environment.evaluator
			end
			
			# Whether the service environment contains the specified keys.
			# This is used for matching environment configuration to service behaviour.
			def include?(keys)
				keys.all?{|key| @environment.include?(key)}
			end
			
			# The name of the service.
			# e.g. `myapp.com`.
			def name
				@evaluator.name
			end
			
			# The logger to use for this service.
			# @returns [Console::Logger]
			def logger
				return Console.logger # .with(name: name)
			end
			
			# Start the service.
			def start
			end
			
			# Setup the service into the specified container.
			# @parameter container [Async::Container::Generic]
			def setup(container)
			end
			
			# Stop the service.
			def stop
			end
		end
	end
end
