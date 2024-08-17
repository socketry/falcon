# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2024, by Samuel Williams.
# Copyright, 2019, by Bryan Powell.

require 'rack/handler'

require_relative '../../falcon/rackup/handler'

module Rack
	module Handler
		Falcon = ::Falcon::Rackup::Handler
		register :falcon, Falcon
	end
end
