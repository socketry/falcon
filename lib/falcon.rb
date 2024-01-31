# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2023, by Samuel Williams.

require_relative "falcon/server"

# Falcon, running on Rails, requires specific configuration:
require_relative "falcon/railtie" if defined?(Rails::Railtie)
