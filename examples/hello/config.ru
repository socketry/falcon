#!/usr/bin/env falcon --verbose serve -c
# frozen_string_literal: true

run do |env|
	[200, {}, ["Hello World"]]
end
