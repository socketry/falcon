# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020, by Daniel Evans.
# Copyright, 2023-2025, by Samuel Williams.

require "falcon/environment/rack"

service "localhost" do
	include Falcon::Environment::Rack
	count 3
end
