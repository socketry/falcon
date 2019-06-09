#!/usr/bin/env -S falcon host

load :rack, :self_signed, :supervisor

host 'hello.localhost', :rack, :self_signed

# service 'jobs' do
# 	shell ['rake', 'background:jobs:process']
# end
