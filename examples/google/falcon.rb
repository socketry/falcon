#!/usr/bin/env falcon-host
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2023, by Samuel Williams.

load :proxy, :self_signed_tls, :supervisor

supervisor

proxy "google.localhost", :self_signed_tls do
	url 'https://www.google.com'
end

proxy "codeotaku.localhost", :self_signed_tls do
	url 'https://www.codeotaku.com'
end
