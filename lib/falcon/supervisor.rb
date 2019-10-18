# Copyright, 2018, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'async/io/endpoint'

require_relative 'proxy'
require_relative 'redirection'

require 'async/container'
require 'async/container/controller'
require 'async/http/endpoint'

module Falcon
	class Supervisor
		class Statistics
			PS = "ps"
			
			def initialize(pgid: Process.ppid, ps: PS)
				@ppid = pgid
				@ps = ps
			end
			
			# pid: Process Identifier
			# pmem: Percentage Memory used.
			# pcpu: Percentage Processor used.
			# time: The process time used (executing on CPU).
			# vsz: Virtual Size in kilobytes
			# rss: Resident Set Size in kilobytes
			# etime: The process elapsed time.
			# command: The name of the process.
			COLUMNS = "pid,pmem,pcpu,time,vsz,rss,etime,command"
			
			def capture
				input, output = IO.pipe
				
				system(@ps, "--ppid", @ppid.to_s, "-o", COLUMNS, out: output, pgroup: true)
				output.close
				
				header, *lines = input.readlines.map(&:strip)
				
				keys = header.split(/\s+/).map(&:downcase)
				
				processes = lines.map do |line|
					keys.zip(line.split(/\s+/, keys.size)).to_h
				end
				
				return processes
			end
		end
		
		def initialize(endpoint)
			@endpoint = endpoint
		end
		
		def restart(message)
			# Tell the parent of this process group to spin up a new process group/container.
			# Wait for that to start accepting new connections.
			# Stop accepting connections.
			# Wait for existing connnections to drain.
			# Terminate this process group.
			
			signal = message[:signal] || :INT
			
			# Sepukku:
			Process.kill(signal, -Process.getpgrp)
		end
		
		def statistics(message)
			statistics = Statistics.new
			
			statistics.capture
		end
		
		def handle(message)
			case message[:please]
			when 'restart'
				self.restart(message)
			when 'statistics'
				self.statistics(message)
			end
		end
		
		def run
			Async.logger.info("Binding to #{@endpoint}")
			@endpoint.accept do |peer|
				stream = Async::IO::Stream.new(peer)
				
				while message = stream.gets("\0")
					response = handle(JSON.parse(message, symbolize_names: true))
					stream.puts(response.to_json, separator: "\0")
				end
			end
		end
	end
end
