# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2021, by Samuel Williams.
# Copyright, 2019, by Sho Ito.

require 'build/environment'

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
	class Configuration
		# Initialize an empty configuration.
		def initialize
			@environments = {}
		end
		
		# The map of named environments.
		# @attribute [Hash(String, Build::Environment)]
		attr :environments
		
		# Enumerate all environments that have the specified key.
		# @parameter key [Symbol] Filter environments that don't have this key.
		def each(key = :authority)
			return to_enum(key) unless block_given?
			
			@environments.each do |name, environment|
				environment = environment.flatten
				
				if environment.include?(key)
					yield environment
				end
			end
		end
		
		# Add the named environment to the configuration.
		def add(environment)
			name = environment.name
			
			unless name
				raise ArgumentError, "Environment name is nil #{environment.inspect}"
			end
			
			environment = environment.flatten
			
			raise KeyError.new("#{name.inspect} is already set", key: name) if @environments.key?(name)
			
			@environments[name] = environment
		end
		
		# Load the specified configuration file. See {Loader#load_file} for more details.
		def load_file(path)
			Loader.load_file(self, path)
		end
		
		# The domain specific language for loading configuration files.
		class Loader
			# Initialize the loader, attached to a specific configuration instance.
			# Any environments generated by the loader will be added to the configuration.
			# @parameter configuration [Configuration]
			# @parameter root [String] The file-system root path for relative path computations.
			def initialize(configuration, root = nil)
				@loaded = {}
				@configuration = configuration
				@environments = {}
				@root = root
			end
			
			# The file-system root path which is injected into the environments as required.
			# @attribute [String]
			attr :root
			
			# The attached configuration instance.
			# @attribute [Configuration]
			attr :configuration
			
			# Load the specified file into the given configuration.
			# @parameter configuration [Configuration]
			# @oaram path [String] The path to the configuration file, e.g. `falcon.rb`.
			def self.load_file(configuration, path)
				path = File.realpath(path)
				root = File.dirname(path)
				
				loader = self.new(configuration, root)
				
				loader.instance_eval(File.read(path), path)
			end
			
			# Load specific features into the current configuration.
			#
			# Falcon provides default environments for different purposes. These are included in the gem, in the `environments/` directory. This method loads the code in those files into the current configuration.
			#
			# @parameter features [Array(Symbol)] The features to load.
			def load(*features)
				features.each do |feature|
					next if @loaded.include?(feature)
					
					case feature
					when Symbol
						relative_path = File.join(__dir__, "environments", "#{feature}.rb")
						
						self.instance_eval(File.read(relative_path), relative_path)
						
						@loaded[feature] = relative_path
					when Module
						feature.load(self)
						
						@loaded[feature] = feature
					else
						raise LoadError, "Unsure about how to load #{feature}!"
					end
				end
			end
			
			# Add the named environment, with zero or more parent environments, defined using the specified `block`.
			# @parameter name [String] The name of the environment.
			# @parameter parents [Array(Symbol)] The names of the parent environments to inherit.
			# @yields {...} The block that will generate the environment.
			def environment(name, *parents, &block)
				raise KeyError.new("#{name} is already set", key: name) if @environments.key?(name)
				@environments[name] = merge(name, *parents, &block)
			end
			
			# Define a host with the specified name.
			# Adds `root` and `authority` keys.
			# @parameter name [String] The name of the environment, usually a hostname.
			def host(name, *parents, &block)
				environment = merge(name, *parents, &block)
				
				environment[:root] = @root
				environment[:authority] = name
				
				@configuration.add(environment.flatten)
			end
			
			# Define a proxy with the specified name.
			# Adds `root` and `authority` keys.
			# @parameter name [String] The name of the environment, usually a hostname.
			def proxy(name, *parents, &block)
				environment = merge(name, :proxy, *parents, &block)
				
				environment[:root] = @root
				environment[:authority] = name
				
				@configuration.add(environment.flatten)
			end
			
			# Define a rack application with the specified name.
			# Adds `root` and `authority` keys.
			# @parameter name [String] The name of the environment, usually a hostname.
			def rack(name, *parents, &block)
				environment = merge(name, :rack, *parents, &block)
				
				environment[:root] = @root
				environment[:authority] = name
				
				@configuration.add(environment.flatten)
			end
			
			# Define a supervisor instance
			# Adds `root` key.
			def supervisor(&block)
				name = File.join(@root, "supervisor")
				environment = merge(name, :supervisor, &block)
				
				environment[:root] = @root
				
				@configuration.add(environment.flatten)
			end
				
			private
			
			# Build a new environment with the specified name and the given parents.
			# @parameter name [String]
			# @parameter parents [Array(Build::Environment)]
			# @yields {...} The block that will generate the environment.
			def merge(name, *parents, &block)
				environments = parents.map{|name| @environments.fetch(name)}
				
				parent = Build::Environment.combine(*environments)
				
				Build::Environment.new(parent, name: name, &block)
			end
		end
	end
end
