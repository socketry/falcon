# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2023, by Samuel Williams.

require 'rackup/handler'

require_relative '../../falcon/rackup/handler'

module Rackup
	module Handler
		Falcon = ::Falcon::Rackup::Handler
		register :falcon, Falcon
	end
end
