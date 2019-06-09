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

require 'build/environment'

module Falcon
	class Configuration
		def initialize(verbose = false)
			@environments = {}
		end
		
		attr :environments
		
		def each(key = :authority)
			return to_enum(key) unless block_given?
			
			@environments.each do |name, environment|
				environment = environment.flatten
				
				if environment.include?(key)
					yield environment
				end
			end
		end
		
		def add(environment)
			name = environment.name
			
			unless name
				raise ArgumentError, "Environment name is nil #{environment.inspect}"
			end
			
			environment = environment.flatten
			
			raise KeyError.new("#{name.inspect} is already set", key: name) if @environments.key?(name)
			
			@environments[name] = environment
		end
		
		def load_file(path)
			Loader.load_file(self, path)
		end
		
		class Loader
			def initialize(configuration, root = nil)
				@loaded = {}
				@configuration = configuration
				@environments = {}
				@root = root
			end
			
			attr :path
			attr :configuration
			
			def self.load_file(configuration, path)
				path = File.realpath(path)
				root = File.dirname(path)
				
				loader = self.new(configuration, root)
				
				loader.instance_eval(File.read(path), path)
			end
			
			def load(*features)
				features.each do |feature|
					next if @loaded.include?(feature)
					
					relative_path = File.join(__dir__, "configurations", "#{feature}.rb")
					
					self.instance_eval(File.read(relative_path), relative_path)
					
					@loaded[feature] = relative_path
				end
			end
			
			def add(name, *parents, &block)
				raise KeyError.new("#{name} is already set", key: name) if @environments.key?(name)
				
				environments = parents.map{|name| @environments.fetch(name)}
				
				parent = Build::Environment.combine(*environments)
				
				@environments[name] = merge(name, *parents, &block)
			end
				
			def host(name, *parents, &block)
				environment = merge(name, :host, *parents, &block)
				
				environment[:root] = @root
				environment[:authority] = name
				
				@configuration.add(environment.flatten)
			end
			
			def proxy(name, *parents, &block)
				environment = merge(name, :proxy, *parents, &block)
				
				environment[:root] = @root
				environment[:authority] = name
				
				@configuration.add(environment.flatten)
			end
			
			def rack(name, *parents, &block)
				environment = merge(name, :rack, *parents, &block)
				
				environment[:root] = @root
				environment[:authority] = name
				
				@confguration.add(environment.flatten)
			end
			
			def supervisor
				environment = merge(:supervisor, :supervisor)
				
				environment[:root] = @root
				
				@configuration.add(environment.flatten)
			end
				
			private
			
			def merge(name, *parents, &block)
				environments = parents.map{|name| @environments.fetch(name)}
				
				parent = Build::Environment.combine(*environments)
				
				return Build::Environment.new(parent, name: name, &block)
			end
		end
	end
end
