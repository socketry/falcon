# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2023-2025, by Samuel Williams.

require "rackup/handler"

require_relative "../../falcon/rackup/handler"

# Generally speaking, you should not require this file directly, or assume the existance of the `Rackup::Handler::Falcon` constant. Instead, use `Rackup::Handler.get(:falcon)` to load and access the handler.

module Rackup
	module Handler
		# Sinatra (and possibly others) try to extract the name using the final part of the class path, so we define a new class in the `Rack::Handler` namespace that inherits from `Falcon::Rackup::Handler`, that follows that convention.
		class Falcon < ::Falcon::Rackup::Handler
		end
		
		# Rack (v3) expects a class for the handler constant, so we explicitly pass `Falcon` to `register` to ensure Rack can find the handler using the registered name.
		register :falcon, Falcon
	end
end
