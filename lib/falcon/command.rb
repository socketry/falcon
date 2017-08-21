# Copyright, 2017, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

require_relative 'server'

require 'async/container'

require 'samovar'
require 'etc'

require 'rack/builder'
require 'rack/server'

module Falcon
	module Command
		def self.default_concurrency
			Etc.nprocessors
		rescue
			2
		end
		
		def self.parse(*args)
			Top.parse(*args)
		end
		
		class Serve < Samovar::Command
			self.description = "Run an HTTP server."
			
			options do
				option '-c/--config <path>', "Rackup configuration file to load", default: 'config.ru'
				option '-n/--concurrency <count>', "Number of processes to start", default: Command.default_concurrency, type: Integer
				
				option '-b/--bind <address>', "Bind to the given hostname/address", default: "tcp://localhost:9292"
				
				option '--forked | --threaded', "Select a specific concurrency model", key: :container, default: :threaded
			end
			
			def container_class
				case @options[:container]
				when :threaded
					require 'async/container/threaded'
					return Async::Container::Threaded
				when :forked
					require 'async/container/forked'
					return Async::Container::Forked
				end
			end
			
			def run
				app, options = Rack::Builder.parse_file(@options[:config])
				
				container_class.new(concurrency: @options[:concurrency]) do
					server = Falcon::Server.new(app, [
						Async::IO::Endpoint.parse(@options[:bind], reuse_port: true)
					])
					
					server.run
				end
			end
			
			def invoke
				run
				
				sleep
			end
		end
		
		class Top < Samovar::Command
			self.description = "An asynchronous HTTP client/server toolset."
			
			nested '<command>',
				'serve' => Serve
				# 'get' => Get
				# 'post' => Post
				# 'head' => Head,
				# 'put' => Put,
				# 'delete' => Delete
				
			def invoke(program_name: File.basename($0))
				if @command
					@command.invoke
				else
					print_usage(program_name)
				end
			end
		end
	end
end
