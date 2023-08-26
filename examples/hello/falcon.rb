#!/usr/bin/env falcon-host
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2020, by Samuel Williams.

load :rack, :self_signed_tls, :supervisor

supervisor

rack 'hello.localhost', :self_signed_tls do
	# scheme 'http'
	# protocol {Async::HTTP::Protocol::HTTP1}
	# 
	# endpoint do
	# 	Async::HTTP::Endpoint.for(scheme, "localhost", port: 9292, protocol: protocol)
	# end
	
	append preload "preload.rb"
	
	# Process will connect to supervisor to report statistics periodically, otherwise it would be killed.
	# report :supervisor
end

# service 'jobs' do
# 	shell ['rake', 'background:jobs:process']
# end
