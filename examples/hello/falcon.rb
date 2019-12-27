#!/usr/bin/env falcon-host

load :rack, :self_signed_tls, :supervisor

rack 'hello.localhost', :self_signed_tls do
	endpoint do
		Async::HTTP::Endpoint.parse("http://localhost:9292")
	end
	
	protocol {Async::HTTP::Protocol::HTTP1}
	scheme 'http'
end

# supervisor

# service 'jobs' do
# 	shell ['rake', 'background:jobs:process']
# end
