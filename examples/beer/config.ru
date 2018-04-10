#!/usr/bin/env falcon --verbose serve -c

def bottles(n)
	n == 1 ? "#{n} bottle" : "#{n} bottles"
end

run lambda {|env|
	task = Async::Task.current
	body = Async::HTTP::Body.new
	
	body.write("<!DOCTYPE html><html><head><title>99 Bottles of Beer</title></head><body>")
	
	task.async do |task|
		99.downto(1) do |i|
			body.write("<p>#{bottles(i)} of beer on the wall, ")
			task.sleep(1)
			body.write("#{bottles(i)} of beer, ")
			task.sleep(1)
			body.write("take one down and pass it around, ")
			task.sleep(1)
			body.write("#{bottles(i-1)} of beer on the wall.</p>")
			task.sleep(1)
		end
		
		body.write("</body></html>")
		body.finish
	end
	
	[200, {'content-type' => 'text/html'}, body]
}
