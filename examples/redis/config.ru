# frozen_string_literal: true

require 'sinatra/base'
require 'async/redis'
require 'async/clock'

CLIENT = Async::Redis::Client.new(Async::Redis.local_endpoint)

class MyApp < Sinatra::Base
	get "/" do
		puts "Starting BLPOP SLEEP..."
		duration = Async::Clock.measure do
			CLIENT.call "BLPOP", "SLEEP", 1
		end
		puts "Finished BLPOP SLEEP after #{duration.round(2)}s"
		
		"ok"
	end
end

use MyApp # Then, it will get to Sinatra.
run lambda {|env| [404, {}, []]} # Bottom of the stack, give 404.

# Start server like this:
# falcon --verbose serve --threaded --count 1 --bind http://localhost:9292

# Test server, e.g.:
# time ab -n 64 -c 64 http://localhost:9292/
