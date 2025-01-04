#!/usr/bin/env falcon-host
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2025, by Samuel Williams.

load :rack, :self_signed_tls, :supervisor

rack "beer.localhost", :self_signed_tls

supervisor
