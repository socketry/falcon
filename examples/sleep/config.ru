# frozen_string_literal: true

require "async"

run do
	body = Async::HTTP::Body::Writable.new
	
	Async do |task|
		task.defer_stop do
			30.times do
				body.write "(#{Time.now}) Hello World #{Process.pid}\n"
				sleep 1
			end
		end
	ensure
		Console.info(self, "Closing body...")
		body.close
	end
	
	[200, {}, body]
end
