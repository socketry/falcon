#!/usr/bin/env falcon --verbose serve -c

class MyApp
	def initialize(app)
		@app = app
		
		@words = File.readlines('/usr/share/dict/words', chomp: true).each_slice(3).to_a
	end
	
	def call(env)
		body = Async::HTTP::Body::Writable.new(queue: Async::LimitedQueue.new(8))
		
		Async do |task|
			@words.each do |words|
				Async.logger.debug("Sending #{words.inspect}")
				body.write(words.join(",") + "\n")
				task.sleep(1)
			end
		ensure
			body.close($!)
		end
		
		return [200, [], body]
	end
end

# Build the middleware stack:
use MyApp

run lambda {|env| [404, {}, []]}
