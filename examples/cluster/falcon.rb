#!/usr/bin/env async-service
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "protocol/http/middleware"

require "falcon/environment/cluster"

addresses_path = File.expand_path(ENV.fetch("ADDRESSES_PATH", "addresses.txt"), __dir__)
File.write(addresses_path, "")

record_addresses = Module.new do
	define_method(:prepare_worker!) do |instance, listener:|
		super(instance, listener: listener)
		
		File.open(addresses_path, "a") do |file|
			file.flock(File::LOCK_EX)
			listener.addresses.each do |address|
				file.puts(address.inspect_sockaddr) if address.ip?
			end
		end
	end
end

service "cluster" do
	include Falcon::Environment::Cluster
	include record_addresses
	
	count 2
	
	def url
		"http://localhost:0"
	end
	
	middleware do
		Protocol::HTTP::Middleware::HelloWorld
	end
end
