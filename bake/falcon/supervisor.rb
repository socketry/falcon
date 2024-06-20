# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2023, by Samuel Williams.

def initialize(context)
	super
	
	require 'io/endpoint/unix_endpoint'
	require 'io/stream'
	require 'json'
	
	@path = "supervisor.ipc"
end

# Restart the process group that the supervisor belongs to.
def restart
	connect do |stream|
		stream.puts({please: 'restart'}.to_json, separator: "\0")
		return JSON.parse(stream.gets("\0"), symbolize_names: true)
	end
end

# Ask the supervisor for metrics relating to the process group that the supervisor belongs to.
# @returns [Hash] The metrics, organised by process ID.
def metrics
	connect do |stream|
		stream.puts({please: 'metrics'}.to_json, separator: "\0")
		return JSON.parse(stream.gets("\0"), symbolize_names: true)
	end
end

private

# The endpoint the supervisor is bound to.
def endpoint
	::IO::Endpoint.unix(@path)
end

def connect
	endpoint.connect do |stream|
		yield IO::Stream(stream)
	end
end
