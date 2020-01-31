#!/usr/bin/env falcon-host

load :proxy, :self_signed_tls, :supervisor

supervisor

proxy "google.localhost", :self_signed_tls do
	url 'https://www.google.com'
end

proxy "codeotaku.localhost", :self_signed_tls do
	url 'https://www.codeotaku.com'
end
