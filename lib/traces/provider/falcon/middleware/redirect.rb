# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require_relative "../../../../falcon/middleware/redirect"

require "traces/provider"

Traces::Provider(Falcon::Middleware::Redirect) do
	def call(request)
		Traces.trace("falcon.middleware.redirect.call", attributes: {authority: request.authority}) do
			super
		end
	end
end
