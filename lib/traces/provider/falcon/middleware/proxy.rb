# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require_relative "../../../../falcon/middleware/proxy"

require "traces/provider"

Traces::Provider(Falcon::Middleware::Proxy) do
	def call(request)
		attributes = {
			"authority" => request.authority,
			"method" => request.method,
			"path" => request.path,
			"version" => request.version,
		}
		
		Traces.trace("falcon.middleware.proxy.call", attributes: attributes) do
			super
		end
	end
end
