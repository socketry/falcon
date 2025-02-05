# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2023, by Samuel Williams.

require "falcon/environment/proxy"

service "localhost" do
	include Falcon::Environment::Proxy
	url "https://www.google.com"
end
