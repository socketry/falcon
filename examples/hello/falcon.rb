#!/usr/bin/env falcon-host

load :rack, :self_signed_tls, :supervisor

rack 'hello.localhost', :self_signed_tls

supervisor

# service 'jobs' do
# 	shell ['rake', 'background:jobs:process']
# end
