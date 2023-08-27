# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2023, by Samuel Williams.

require_relative '../services'

require 'async/container/controller'

module Falcon
	module Controller
		# A generic controller for serving an application.
		# Hosts several {Services} based on the command configuration.
		#
		# The configuration is provided by {Command::Host} and is typically loaded from a `falcon.rb` file. See {Configuration#load_file} for more details.
		class Host < Async::Container::Controller
			# Initialize the virtual controller.
			# @parameter command [Command::Host] The user-specified command-line options.
			def initialize(command, **options)
				@command = command
				
				@configuration = command.configuration
				@services = Services.new(@configuration)
				
				super(**options)
			end
			
			# Create the controller as specified by the command.
			# e.g. `Async::Container::Forked`.
			def create_container
				@command.container_class.new
			end
			
			# Start all specified services.
			def start
				@services.start
				
				super
			end
			
			# Setup all specified services into the container.
			# @parameter container [Async::Container::Generic]
			def setup(container)
				@services.setup(container)
			end
			
			# Stop all specified services.
			def stop(*)
				@services.stop
				
				super
			end
		end
	end
end
