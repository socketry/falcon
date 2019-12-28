#!/usr/bin/env falcon-host

load :rack, :self_signed_tls, :supervisor

rack 'trailers.localhost', :self_signed_tls

supervisor
