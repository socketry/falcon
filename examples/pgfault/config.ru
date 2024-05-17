# frozen_string_literal: true

require "rdkafka"

run do |env|
	[200, {"content-type" => "text/plain"}, ["Hello, World!"]]
end
