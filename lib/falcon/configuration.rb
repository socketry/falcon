# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2025, by Samuel Williams.
# Copyright, 2019, by Sho Ito.

require "async/service"

module Falcon
	# Manages environments which describes how to host a specific application.
	#
	# Environments are key-value maps with lazy value resolution. An environment can inherit from a parent environment, which can provide defaults or shared configuration.
	#
	class Configuration < ::Async::Service::Configuration
		# Load the specified configuration file. See {Loader#load_file} for more details.
		def load_file(path)
			Loader.load_file(self, path)
		end
		
		# The domain specific language for loading configuration files.
		class Loader < ::Async::Service::Loader
			# Load specific features into the current configuration.
			#
			# @deprecated Use `require` instead.
			# @parameter features [Array(Symbol)] The features to load.
			def load(*features)
				features.each do |feature|
					case feature
					when Symbol
						require File.join(__dir__, "environment", "#{feature}.rb")
					else
						raise LoadError, "Unsure about how to load #{feature}!"
					end
				end
			end
			
			# Define a host with the specified name.
			# Adds `root` and `authority` keys.
			# @deprecated Use `service` and `include Falcon::Environment::Server` instead.
			# @parameter name [String] The name of the environment, usually a hostname.
			def host(name, *parents, &block)
				@configuration.add(
					merge(*parents, name: name, root: @root, authority: name, &block)
				)
			end
			
			# Define a proxy with the specified name.
			# Adds `root` and `authority` keys.
			# @deprecated Use `service` and `include Falcon::Environment::Proxy` instead.
			# @parameter name [String] The name of the environment, usually a hostname.
			def proxy(name, *parents, &block)
				@configuration.add(
					merge(:proxy, *parents, name: name, root: @root, authority: name, &block)
				)
			end
			
			# Define a rack application with the specified name.
			# Adds `root` and `authority` keys.
			# @deprecated Use `service` and `include Falcon::Environment::Rack` instead.
			# @parameter name [String] The name of the environment, usually a hostname.
			def rack(name, *parents, &block)
				@configuration.add(
					merge(:rack, *parents, name: name, root: @root, authority: name, &block)
				)
			end
			
			# Define a supervisor instance
			# @deprecated Use `service` and `include Falcon::Environment::Supervisor` instead.
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
				facets = parents.map{|parent| Environment::LEGACY_ENVIRONMENTS.fetch(parent)}
				
				::Async::Service::Environment.build(*facets, **initial, &block)
			end
		end
	end
end
