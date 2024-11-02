#!/usr/bin/env falcon --verbose serve -c
# frozen_string_literal: true

class Benchmark
	def initialize(app)
		@app = app
	end
	
	def hello(env)
		[200, {"content-length" => 12}, ["Hello World\n"]]
	end
	
	PATH_INFO = "PATH_INFO".freeze
	
	SMALL = [200, {}, ["Hello World\n" * 10] * 10].freeze
	
	def small(env)
		SMALL
	end
	
	BIG = [200, {}, ["Hello World\n" * 1000] * 1000].freeze
	
	def big(env)
		BIG
	end
	
	def sleep(env)
		Kernel::sleep(0.1)
		[200, {}, []]
	end
	
	def call(env)
		_, name, *path = env[PATH_INFO].split("/")
		
		method = name&.to_sym
		
		if method and self.respond_to?(method)
			self.send(method, env)
		else
			@app.call(env)
		end
	end
end

use Benchmark

run lambda {|env| [200, {}, ["Hello World"]]}
