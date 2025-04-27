# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

def leak(size: 1024*1024)
	require "async/http/internet/instance"
	
	Sync do
		response = Async::HTTP::Internet.get("http://localhost:8080/?leak=#{size}")
	ensure
		response&.finish
	end
end
