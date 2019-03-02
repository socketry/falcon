#!/usr/bin/env falcon --verbose serve --concurrency 1 --config

class EarlyHints
	def initialize(app)
		@app = app
	end
	
	def call(env)
		path = env['PATH_INFO']
		early_hints = early_hints = env['rack.early_hints']
		
		Async.logger.debug("path: #{path} #{early_hints}")
		
		if path == "/index.html" and early_hints
			early_hints.push("/style.css")
			early_hints.push("/script.js")
		end
		
		@app.call(env)
	end
end

use EarlyHints

use Rack::Static, :urls => [""], :root => __dir__, :index => 'index.html'

run lambda{|env| [404, [], ["Not Found"]]}
