#!/usr/bin/env -S ./bin/falcon virtual

load :rack, :self_signed_tls, :supervisor

rack 'benchmark.local', :self_signed_tls
