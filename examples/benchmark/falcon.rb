#!/usr/bin/env -S ./bin/falcon virtual
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2023, by Samuel Williams.

load :rack, :self_signed_tls, :supervisor

rack "benchmark.local", :self_signed_tls
