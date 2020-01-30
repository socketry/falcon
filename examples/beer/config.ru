#!/usr/bin/env falcon --verbose serve -c

require 'rack'
require 'cgi'

def bottles(n)
	n == 1 ? "#{n} bottle" : "#{n} bottles"
end

# Browsers don't show streaming content until a certain threshold has been met. For most browers, it's about 1024 bytes. So, we have a comment of about that length which we feed to the client before streaming actual content. For more details see https://stackoverflow.com/questions/16909227
COMMENT = "<!--#{'-' * 1024}-->"

# To test this example with the curl command-line tool, you'll need to add the `--no-buffer` flag or set the COMMENT size to the required 4096 bytes in order for curl to start streaming. 
# curl http://localhost:9292/ --no-buffer

run lambda {|env|
	task = Async::Task.current
	body = Async::HTTP::Body::Writable.new
	
	request = Rack::Request.new(env)
	count = (request.params['count'] || 99).to_i
	
	body.write("<!DOCTYPE html><html><head><title>#{count} Bottles of Beer</title></head><body>")
	
	task.async do |task|
		begin
			body.write(COMMENT)
			
			count.downto(1) do |i|
				task.annotate "bottles of beer #{i}"
				
				Async.logger.info(body) {"#{bottles(i)} of beer on the wall..."}
				body.write("<p>#{bottles(i)} of beer on the wall, ")
				task.sleep(0.1)
				body.write("#{bottles(i)} of beer, ")
				task.sleep(0.1)
				body.write("take one down and pass it around, ")
				task.sleep(0.1)
				body.write("#{bottles(i-1)} of beer on the wall.</p>")
				task.sleep(0.1)
				body.write("<script>var child; while (child = document.body.firstChild) child.remove();</script>")
			end
			
			code = File.read(__FILE__)
			body.write("<h1>Source Code</h1>")
			body.write("<pre><code>#{CGI.escapeHTML code}</code></pre>")
			body.write("</body></html>")
		rescue
			puts "Remote end closed connection: #{$!}"
		ensure
			body.close
		end
	end
	
	[200, {'content-type' => 'text/html; charset=utf-8'}, body]
}
