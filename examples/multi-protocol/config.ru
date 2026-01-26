# frozen_string_literal: true

# A simple Rack application that responds to requests
app = proc do |env|
	request = Rack::Request.new(env)
	
	body = "Hello from #{env['SERVER_PROTOCOL']} on port #{env['SERVER_PORT']}!\n"
	body += "Path: #{request.path}\n"
	body += "Method: #{request.request_method}\n"
	
	[200, {"Content-Type" => "text/plain"}, [body]]
end

run app
