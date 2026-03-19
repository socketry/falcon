#!/usr/bin/env falcon --verbose serve -c
# frozen_string_literal: true

require "objspace"

run do |env|
	if env["PATH_INFO"] == "/gc"
		GC.start
	end
	
	fiber_count = ObjectSpace.each_object(Fiber).count
	[200, {}, ["Fiber count: #{fiber_count}"]]
end
