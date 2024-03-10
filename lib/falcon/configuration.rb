# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2023, by Samuel Williams.
# Copyright, 2019, by Sho Ito.

require 'async/service'

module Falcon
	# Manages environments which describes how to host a specific application.
	#
	# Environments are key-value maps with lazy value resolution. An environment can inherit from a parent environment, which can provide defaults
	#
	# A typical configuration file might look something like:
	#
	#	~~~ ruby
	#	#!/usr/bin/env falcon-host
	#	# frozen_string_literal: true
	#	
	#	load :rack, :self_signed_tls, :supervisor
	#	
	#	supervisor
	#	
	#	rack 'hello.localhost', :self_signed_tls do
	#	end
	#	~~~
	#
	class Configuration < ::Async::Service::Configuration
		# Load the specified configuration file. See {Loader#load_file} for more details.
		def load_file(path)
			Loader.load_file(self, path)
		end
		
		def each(key = :authority)
			return to_enum(__method__, key) unless block_given?
			
			@environments.each do |environment|
				evaluator = environment.evaluator
				if evaluator.key?(key)
					yield environment
				end
			end
		end
		
		# The domain specific language for loading configuration files.
		class Loader < ::Async::Service::Loader
			# Load specific features into the current configuration.
			#
			# Falcon provides default environments for different purposes. These are included in the gem, in the `environments/` directory. This method loads the code in those files into the current configuration.
			#
			# @parameter features [Array(Symbol)] The features to load.
			def load(*features)
				features.each do |feature|
					case feature
					when Symbol
						require File.join(__dir__, "environments", "#{feature}.rb")
					else
						raise LoadError, "Unsure about how to load #{feature}!"
					end
				end
			end
			
			# Define a host with the specified name.
			# Adds `root` and `authority` keys.
			# @parameter name [String] The name of the environment, usually a hostname.
			def host(name, *parents, &block)
				@configuration.add(
					merge(*parents, name: name, root: @root, authority: name, &block)
				)
			end
			
			# Define a proxy with the specified name.
			# Adds `root` and `authority` keys.
			# @parameter name [String] The name of the environment, usually a hostname.
			def proxy(name, *parents, &block)
				@configuration.add(
					merge(:proxy, *parents, name: name, root: @root, authority: name, &block)
				)
			end
			
			# Define a rack application with the specified name.
			# Adds `root` and `authority` keys.
			# @parameter name [String] The name of the environment, usually a hostname.
			def rack(name, *parents, &block)
				@configuration.add(
					merge(:rack, *parents, name: name, root: @root, authority: name, &block)
				)
			end
			
			# Define a supervisor instance
			# Adds `root` key.
			def supervisor(&block)
				name = File.join(@root, "supervisor")
				
				@configuration.add(
					merge(:supervisor, name: name, root: @root, &block)
				)
			end
				
			private
			
			# Build a new environment with the specified name and the given parents.
			# @parameter name [String]
			# @parameter parents [Array(Symbol)]
			# @yields {...} The block that will generate the environment.
			def merge(*parents, **initial, &block)
				::Async::Service::Environment.build(**initial) do
					parents.each do |parent|
						Console.warn(self) {"Legacy mapping for #{parent.inspect} should be updated to use `include`!"}
						include(Environments::LEGACY_ENVIRONMENTS[parent])
					end
					
					instance_exec(&block) if block
				end
			end
		end
	end
end
