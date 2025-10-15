# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2025, by Samuel Williams.

require "covered/sus"
include Covered::Sus

ENV["CONSOLE_LEVEL"] ||= "warn"
ENV["TRACES_BACKEND"] ||= "traces/backend/test"
ENV["METRICS_BACKEND"] ||= "metrics/backend/test"
