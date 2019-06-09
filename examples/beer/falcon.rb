#!/usr/bin/env -S falcon host

load :rack, :self_signed, :supervisor

host 'beer.localhost', :rack, :self_signed
