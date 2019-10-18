#!/usr/bin/env falcon-host

load :rack, :self_signed_tls, :supervisor

rack 'beer.localhost', :self_signed_tls

supervisor
