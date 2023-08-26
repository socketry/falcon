# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2021, by Samuel Williams.

require_relative '../controller/host'
require_relative '../configuration'
require_relative '../version'

require 'samovar'
require 'bundler'

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
			
			# The container class to use.
			def container_class
				Async::Container.best_container_class
			end
			
			# Generate a configuration based on the specified {paths}.
			def configuration
				configuration = Configuration.new
				
				@paths.each do |path|
					path = File.expand_path(path)
					configuration.load_file(path)
				end
				
				return configuration
			end
			
			# Prepare a new controller for the command.
			def controller
				Controller::Host.new(self)
			end
			
			# Prepare the environment and run the controller.
			def call
				Console.logger.info(self) do |buffer|
					buffer.puts "Falcon Host v#{VERSION} taking flight!"
					buffer.puts "- Configuration: #{@paths.join(', ')}"
					buffer.puts "- To terminate: Ctrl-C or kill #{Process.pid}"
					buffer.puts "- To reload: kill -HUP #{Process.pid}"
				end
				
				begin
					Bundler.require(:preload)
				rescue Bundler::GemfileNotFound
					# Ignore.
				end
				
				if GC.respond_to?(:compact)
					GC.compact
				end
				
				self.controller.run
			end
		end
	end
end
