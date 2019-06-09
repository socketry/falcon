#!/usr/bin/env -S ./bin/falcon virtual

load :rack, :self_signed, :supervisor

host 'benchmark.local', :rack, :self_signed
