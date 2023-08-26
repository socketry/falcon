#!/usr/bin/env falcon-host
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2021, by Samuel Williams.

load :rack, :self_signed_tls, :supervisor

rack 'trailer.localhost', :self_signed_tls

supervisor
