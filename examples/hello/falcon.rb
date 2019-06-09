#!/usr/bin/env -S falcon host

load :host, :lets_encrypt, :rack, :supervisor

host 'hello.localhost', :rack, :self_signed

supervisor

# service 'jobs' do
# 	shell ['rake', 'background:jobs:process']
# end
