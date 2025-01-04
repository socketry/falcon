# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2025, by Samuel Williams.
# Copyright, 2019, by Bryan Powell.

require "rack/handler"

require_relative "../../falcon/rackup/handler"

# Generally speaking, you should not require this file directly, or assume the existance of the `Rack::Handler::Falcon` constant. Instead, use `Rack::Handler.get(:falcon)` to load and access the handler.

module Rack
	module Handler
		# Rack (v2) expects the constant to be in the `Rack::Handler` namespace, so we define a new handler class in the `Rack::Handler` namespace that inherits from `Falcon::Rackup::Handler`.
		class Falcon < ::Falcon::Rackup::Handler
		end
		
		# Rack (v2) expects a string for the handler constant name. `Falcon.to_s` returns a more human friendly name, so we explicitly pass `Falcon.name` to `register` to ensure Rack can find the handler using the registered name.
		register :falcon, Falcon.name
	end
end
