#!/usr/bin/env -S ./bin/falcon virtual
# frozen_string_literal: true

load :rack, :self_signed_tls, :supervisor

rack 'benchmark.local', :self_signed_tls
