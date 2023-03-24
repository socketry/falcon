
require 'async'

LIMIT = Async::Semaphore.new(8)

run do
	LIMIT.acquire do
		sleep(1)
	end
	
	[200, {}, ['Hello World']]
end

# Run the server:
# > falcon serve --count 1 --bind http://localhost:9292

# Measure the concurrency:
# > benchmark-http concurrency -t 1.2 -c 0.9 http://localhost:9292

