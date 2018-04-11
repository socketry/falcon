#!/usr/bin/env falcon --verbose serve -c

def bottles(n)
	n == 1 ? "#{n} bottle" : "#{n} bottles"
end

# Browsers don't show streaming content until a certain threshold has been met. For most browers, it's about 1024 bytes. So, we have a comment of about that length which we feed to the client before streaming actual content. For more details see https://stackoverflow.com/questions/16909227
COMMENT = "<!--#{'-' * 1024}-->"

run lambda {|env|
	task = Async::Task.current
	body = Async::HTTP::Body.new
	
	body.write("<!DOCTYPE html><html><head><title>99 Bottles of Beer</title></head><body>")
	
	task.async do |task|
		body.write(COMMENT)
		
		99.downto(1) do |i|
			puts "#{bottles(i)} of beer on the wall..."
			body.write("<p>#{bottles(i)} of beer on the wall, ")
			task.sleep(1)
			body.write("#{bottles(i)} of beer, ")
			task.sleep(1)
			body.write("take one down and pass it around, ")
			task.sleep(1)
			body.write("#{bottles(i-1)} of beer on the wall.</p>")
			task.sleep(1)
			body.write("<script>var child; while (child = document.body.firstChild) child.remove();</script>")
		end
		
		body.write("</body></html>")
	rescue
		puts "Remote end closed connection: #{$!}"
	ensure
		body.finish
	end
	
	[200, {'content-type' => 'text/html; charset=utf-8'}, body]
}
