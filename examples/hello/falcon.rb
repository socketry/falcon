#!/usr/bin/env falcon-host

load :rack, :self_signed_tls, :supervisor

rack 'hello.localhost', :self_signed_tls do
	scheme 'http'
	protocol {Async::HTTP::Protocol::HTTP1}
	
	endpoint do
		Async::HTTP::Endpoint.for(scheme, "localhost", port: 9292, protocol: protocol)
	end
	
	append preload "preload.rb"
end

# supervisor

# service 'jobs' do
# 	shell ['rake', 'background:jobs:process']
# end
