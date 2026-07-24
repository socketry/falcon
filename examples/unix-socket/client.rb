#!/usr/bin/env ruby
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2025, by Samuel Williams.

require "async"
require "async/http/client"
require "io/endpoint/unix_endpoint"

SOCKET_PATH = "/tmp/falcon-unix-socket-example.sock"
RESPONSE_MAX_SIZE = 1024

def ping_request
	# Create a unix socket endpoint
	socket = UNIXSocket.new(SOCKET_PATH)

	ping_request = [
		"GET /ping HTTP/1.1",
		"Host: localhost",
		"Connection: close",
		"",
		"",
	]

	socket.write(ping_request.join("\r\n"))

	response = socket.recv(RESPONSE_MAX_SIZE)
	puts "Response: #{response}"
end

puts "🚀 Starting client..."
puts "🏓 Sending PING request...\n"
ping_request

while true
	print "\nEnter a message to reverse (or 'exit' to quit): "
	message = gets

	break if message.nil? || message.strip.downcase == "exit"

	# Create a unix socket endpoint
	socket = UNIXSocket.new(SOCKET_PATH)

	reverse_request = [
		"POST /reverse HTTP/1.1",
		"Host: localhost",
		"Content-Length: #{message.bytesize}",
		"Connection: close",
		"",
		message,
	]

	socket.write(reverse_request.join("\r\n"))

	response = socket.recv(1024)
	puts "\nResponse: #{response}"
end

puts "👋 Exiting client..."
