# frozen_string_literal: true

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

require 'samovar'
require 'async'
require 'json'

require 'async/io/stream'
require 'async/io/unix_endpoint'

module Falcon
	module Command
		# Implements the `falcon supervisor` command.
		#
		# Talks to an instance of the supervisor to issue commands and print results.
		class Supervisor < Samovar::Command
			self.description = "Control and query a specific supervisor."
			
			# The command line options.
			# @attr [Samovar::Options]
			options do
				option "--path <path>", "The control IPC path.", default: "supervisor.ipc"
			end
			
			# Implements the `falcon supervisor restart` command.
			class Restart < Samovar::Command
				self.description = "Restart the process group."
				
				# Send the restart message to the supervisor.
				def call(stream)
					stream.puts({please: 'restart'}.to_json, separator: "\0")
				end
			end
			
			# Implements the `falcon supervisor metrics` command.
			class Metrics < Samovar::Command
				self.description = "Show metrics about the falcon processes."
				
				# Send the metrics message to the supervisor and print the results.
				def call(stream)
					stream.puts({please: 'metrics'}.to_json, separator: "\0")
					response = JSON.parse(stream.gets("\0"), symbolize_names: true)
					
					pp response
				end
			end
			
			# The nested command to execute.
			# @name nested
			# @attr [Command]
			nested :command, {
				'restart' => Restart,
				'metrics' => Metrics,
			}, default: 'metrics'
			
			# The endpoint the supervisor is bound to.
			def endpoint
				Async::IO::Endpoint.unix(@options[:path])
			end
			
			# Connect to the supervisor and execute the requested command.
			def call
				Async do
					endpoint.connect do |socket|
						stream = Async::IO::Stream.new(socket)
						
						@command.call(stream)
					end
				end
			end
		end
	end
end
