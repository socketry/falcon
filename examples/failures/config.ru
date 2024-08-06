require 'typhoeus'

run lambda{|env|
	ttl = env['PATH_INFO'].split('/').last.to_i
	localhost = "127.0.0.#{rand(1...255)}"
	
	pp ttl: ttl, thread: Thread.current.name, localhost: localhost
	
	if ttl < 2
		hydra = Typhoeus::Hydra.new
		2.times do
			hydra.queue(Typhoeus::Request.new("#{localhost}:9292/#{ttl+1}"))
		end
		response = Typhoeus.get("http://#{localhost}:9292/#{ttl+1}")
		
		hydra.run
	end
	
	[200, [], [ttl.to_s]]
}