#!/usr/bin/env ruby
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "async/http/internet/instance"

url = ENV.fetch("ENVOY_URI", "http://127.0.0.1:10000")
deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 20
workers = {}

Sync do
	until workers.size == 2 || Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline
		begin
			Async::HTTP::Internet.get(url) do |response|
				if response.success?
					worker_id = response.headers["x-worker-id"]
					workers[worker_id] ||= response.read
				end
			end
		rescue Errno::ECONNREFUSED, EOFError
			# Envoy may still be connecting to the xDS control plane.
		end
		
		sleep(0.1) unless workers.size == 2
	end
end

abort "Envoy did not route requests to both workers." unless workers.size == 2

workers.each_value{|body| puts(body)}
