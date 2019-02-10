
Async.logger.debug!

class EarlyHints
	def initialize(app)
		@app = app
	end
	
	def call(env)
		if env['PATH_INFO'] == "/index.html" and early_hints = env['rack.early_hints']
			early_hints.call([
				["link", "</style.css>; rel=preload; as=style"],
				["link", "</script.js>; rel=preload; as=script"],
			])
		end
		
		@app.call(env)
	end
end

use EarlyHints
use Rack::Static, :urls => [""], :root => __dir__, :index => 'index.html'
run lambda{|env| [404, [], ["Not Found"]]}
