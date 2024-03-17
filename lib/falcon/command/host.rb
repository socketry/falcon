# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2023, by Samuel Williams.

require_relative 'paths'
require_relative '../version'

require 'samovar'
require 'async/service/controller'

module Falcon
	module Command
		# Implements the `falcon host` command. Designed for *deployment*.
		#
		# Manages a {Controller::Host} instance which is responsible for running applications in a production environment.
		class Host < Samovar::Command
			self.description = "Host the specified applications."
			
			# One or more paths to the configuration files.
			# @name paths
			# @attribute [Array(String)]
			many :paths, "Service configuration paths.", default: ["falcon.rb"]
			
			include Paths
			
			# The container class to use.
			def container_class
				Async::Container.best_container_class
			end
			
			# Prepare the environment and run the controller.
			def call
				Console.logger.info(self) do |buffer|
					buffer.puts "Falcon Host v#{VERSION} taking flight!"
					buffer.puts "- Configuration: #{@paths.join(', ')}"
					buffer.puts "- To terminate: Ctrl-C or kill #{Process.pid}"
					buffer.puts "- To reload: kill -HUP #{Process.pid}"
				end
				
				Async::Service::Controller.run(self.configuration, container_class: self.container_class)
			end
		end
	end
end
