# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2023, by Samuel Williams.

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
