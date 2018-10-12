#!/usr/bin/env falcon --verbose serve -c

class Benchmark
	def initialize(app)
		@app = app
	end
	
	PATH_INFO = 'PATH_INFO'.freeze
	
	def small(env)
		[200, {}, ["Hello World"]]
	end
	
	def big(env)
		[200, {}, ["Hello World\n" * 1000]]
	end
	
	def call(env)
		path = env[PATH_INFO].split("/").last.to_sym
		
		if respond_to? path
			self.send(path, env)
		else
			@app.call(env)
		end
	end
end

use Benchmark

run lambda {|env| [200, {}, ["Hello World"]]}

