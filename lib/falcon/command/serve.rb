# frozen_string_literal: true

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

require_relative '../server'
require_relative '../endpoint'
require_relative '../controller/serve'

require 'async/container'

require 'async/io/trap'
require 'async/io/host_endpoint'
require 'async/io/shared_endpoint'
require 'async/io/ssl_endpoint'

require 'samovar'

require 'rack/builder'
require 'rack/server'

require 'bundler'

module Falcon
	module Command
		class Serve < Samovar::Command
			self.description = "Run an HTTP server for development purposes."
			
			options do
				option '-b/--bind <address>', "Bind to the given hostname/address.", default: "https://localhost:9292"
				
				option '-p/--port <number>', "Override the specified port.", type: Integer
				option '-h/--hostname <hostname>', "Specify the hostname which would be used for certificates, etc."
				option '-t/--timeout <duration>', "Specify the maximum time to wait for non-blocking operations.", type: Float, default: nil
				
				option '-c/--config <path>', "Rackup configuration file to load.", default: 'config.ru'
				option '--preload <path>', "Preload the specified path before creating containers."
				
				option '--cache', "Enable the response cache."
				
				option '--forked | --threaded | --hybrid', "Select a specific parallelism model.", key: :container, default: :forked
				
				option '-n/--count <count>', "Number of instances to start.", default: Async::Container.processor_count, type: Integer
				
				option '--forks <count>', "Number of forks (hybrid only).", type: Integer
				option '--threads <count>', "Number of threads (hybrid only).", type: Integer
			end
			
			def container_class
				case @options[:container]
				when :threaded
					return Async::Container::Threaded
				when :forked
					return Async::Container::Forked
				when :hybrid
					return Async::Container::Hybrid
				end
			end
			
			def verbose?
				@parent&.verbose?
			end
			
			def cache?
				@options[:cache]
			end
			
			def load_app
				rack_app, _ = Rack::Builder.parse_file(@options[:config])
				
				return Server.middleware(rack_app, verbose: self.verbose?, cache: self.cache?)
			end
			
			def slice_options(*keys)
				# TODO: Ruby 2.5 introduced Hash#slice
				options = {}
				
				keys.each do |key|
					if @options.key?(key)
						options[key] = @options[key]
					end
				end
				
				return options
			end
			
			def container_options
				slice_options(:count, :forks, :threads)
			end
			
			def endpoint_options
				slice_options(:hostname, :port, :reuse_port, :timeout)
			end
			
			def endpoint
				Endpoint.parse(@options[:bind], **endpoint_options)
			end
			
			def client_endpoint
				Async::HTTP::Endpoint.parse(@options[:bind], **endpoint_options)
			end
			
			def client
				Async::HTTP::Client.new(client_endpoint)
			end
			
			def controller
				Controller::Serve.new(self)
			end
			
			def call
				Async.logger.info(self) do |buffer|
					buffer.puts "Falcon v#{VERSION} taking flight! Using #{self.container_class} #{self.container_options}."
					buffer.puts "- Binding to: #{self.endpoint}"
					buffer.puts "- To terminate: Ctrl-C or kill #{Process.pid}"
					buffer.puts "- To reload configuration: kill -HUP #{Process.pid}"
				end
				
				if path = @options[:preload]
					full_path = File.expand_path(path)
					load(full_path)
				end
				
				if GC.respond_to?(:compact)
					GC.compact
				end
				
				self.controller.run
			end
		end
	end
end
