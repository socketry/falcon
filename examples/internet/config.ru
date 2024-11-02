# frozen_string_literal: true

require "async"
require "async/http/internet"

# Experimental.
require "kernel/sync"

class Search
	def initialize(app)
		@internet = Async::HTTP::Internet.new
		
		@app = app
	end
	
	# This method uses the `Async` method to create a reactor if required, and then executes the contained code without waiting for the result. So even if the search query takes a long time (e.g. 100ms), it won't hold up the request processing.
	def async(close: !Async::Task.current?)
		Async do
			response = @internet.get("https://google.com/search?q=async+ruby")
			
			puts response.inspect
		ensure
			response&.finish
		end
	end
	
	# This method uses the experimental `Sync` method to create a reactor if required. If the code is already running in a reactor, it runs synchronously, otherwise it's effectively the same as `Async` and a blocking operation. This allow you to write efficient non-blocking code that works in both traditional web application servers, but gains additional scalability in `Async`-aware servers like Falcon.
	# You can achieve a similar result by calling `Async{}.wait`, but this is less efficient as it will allocate a sub-task even thought it's not needed.
	def sync(close: !Async::Task.current?)
		Sync do
			response = @internet.get("https://google.com/search?q=async+ruby")
			
			puts response.inspect
		ensure
			response&.finish
		end
	end
	
	# The only point of this is to invoke one of the above two methods.
	def call(env)
		case env["PATH_INFO"]
		when "/sync"
			self.sync
		when "/async"
			self.async
		end
		
		return @app.call(env)
	end
end

use Search

run lambda{|env| [404, [], []]}
