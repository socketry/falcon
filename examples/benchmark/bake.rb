# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2024, by Samuel Williams.

require "etc"

require "async"
require "async/process"
require "async/clock"
require "async/http/endpoint"

def hello
	@config_path = File.expand_path("../hello/config.ru", __dir__)
	@request_path = "/"
end

def small
	@config_path = File.expand_path("config.ru", __dir__)
	@request_path = "/small"
end

def big
	@config_path ||= File.expand_path("config.ru", __dir__)
	@request_path ||= "/big"
end

def compare
	host = "http://127.0.0.1:9292"
	
	threads = 2 # Etc.nprocessors
	
	perf = ["perf", "record", "-F", "max", "-a", "--"]
	strace = ["strace", "-f", "-e", "network,read,write", "-c", "--"]
	
	servers = [
		["puma", "--bind", host.gsub("http", "tcp")],
		# [*strace, "puma", "--workers", threads.to_s, "--bind", host.gsub("http", "tcp")],
		# ["rbspy", "record", "--", "falcon", "serve", "--threaded", "--bind", host, "--config"]
		["../../bin/falcon", "serve", "--bind", host, "--config"],
	]
	
	Console.logger.info!
	
	endpoint = Async::HTTP::Endpoint.parse(host)
	
	servers.each do |command|
		Async do |task|
			begin
				server_status = nil
				
				# This computes the startup time:
				start_time = Async::Clock.now
				child_process = nil
				
				server_task = task.async do
					$stderr.puts "Starting #{command.first}"
					child_process = Async::Process::Child.new(*command, @config_path)
					child_process.wait
				end
				
				begin
					unless server_status.nil?
						raise RuntimeError, "Server failed to start: #{server_status}"
					end
					
					socket = endpoint.connect
					
					request = Protocol::HTTP::Request.new("http", "localhost", "GET", @request_path)
					protocol = Async::HTTP::Protocol::HTTP1.client(socket)
					
					response = protocol.call(request)
					
					Console.logger.info(response, "Headers:", response.headers.to_h) {"Response body size: #{response.read.bytesize}"}
					
					response.close
					
					socket.close
				rescue Errno::ECONNREFUSED, Errno::ECONNRESET
					task.sleep 0.01
					
					retry
				end
				
				end_time = Async::Clock.now
				
				Console.logger.info(command) {"** Took #{end_time - start_time}s to first response."}
				
				n = 2
				
				threads.times do |n|
					c = (n*n).to_s
					puts "Running #{command.first} with #{c} concurrent connections..."
					
					Async::Process.spawn("curl", "-o", "/dev/null", "#{host}#{@request_path}")
					
					# Async::Process.spawn("ab", "-k", "-n", "1000", "#{host}#{@request_path}")
					
					Async::Process.spawn("wrk", "-c", c.to_s, "-t", (n).to_s, "-d", "10", "#{host}#{@request_path}")
				end
			ensure
				child_process.kill(:INT)
			end
		end
	end
end
