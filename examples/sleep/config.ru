
require 'async'

run do
	body = Async::HTTP::Body::Writable.new
	
	Async do
		30.times do
			body.write "(#{Time.now}) Hello World #{Process.pid}\n"
			sleep 1
		end
	ensure
		body.close
	end
	
	[200, {}, body]
end

# Run the server:
# > falcon serve --count 1 --bind http://localhost:9292

# Measure the concurrency:
# > benchmark-http concurrency -t 1.2 -c 0.9 http://localhost:9292

