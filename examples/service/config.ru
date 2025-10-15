#!/usr/bin/env falcon --verbose serve -c
# frozen_string_literal: true

run do |env|
	# To test the fiber profiler, you can uncomment the following line:
	# Fiber.blocking{sleep 0.1}
	[200, {}, ["Hello World"]]
end
