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

require_relative '../server'
require_relative '../verbose'

require 'async/container'

require 'async/http/client'
require 'async/http/url_endpoint'

require 'samovar'

module Falcon
	module Command
		class Statistics
			def initialize
				@samples = []
			end
			
			attr :samples
			
			def average
				if @samples.any?
					@samples.sum / @samples.count
				end
			end
			
			def variance
				return nil if @samples.count < 2
				
				average = self.average
				
				return @samples.map{|n| n - average}.sum / @samples.count
			end
			
			def standard_deviation
				if variance = self.variance
					Math.sqrt(variance)
				end
			end
			
			def standard_error
				if standard_deviation = self.standard_deviation
					standard_deviation / Math.sqrt(@samples.count)
				end
			end
			
			def measure
				start_time = Time.now
				
				result = yield
				
				@samples << Time.now - start_time
				
				return result
			end
			
			def sample(&block)
				# warmup
				yield
				
				100.times do
					measure(&block)
				end
			end
			
			def print(out = STDOUT)
				out.puts "#{@samples.count} samples. #{1.0 / self.average} per second. #{variance}."
			end
		end
		
		class Benchmark < Samovar::Command
			self.description = "Benchmark an HTTP server."
			
			options do
				option '-c/--config <path>', "Rackup configuration file to load", default: 'config.ru'
				option '-n/--concurrency <count>', "Number of processes to start", default: Async::Container.hardware_concurrency, type: Integer
				
				option '-b/--bind <address>', "Bind to the given hostname/address", default: "tcp://localhost:9292"
				
				option '--forked | --threaded', "Select a specific concurrency model", key: :container, default: :threaded
			end
			
			many :hosts
			
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
			
			def run(url)
				endpoint = Async::HTTP::URLEndpoint.parse(url)
				request_path = endpoint.url.request_uri
				
				Async.logger.info "Benchmarking #{url}..."
				
				container_class.new(concurrency: @options[:concurrency]) do |task|
					client = Async::HTTP::Client.new(endpoint, endpoint.protocol)
					statistics = Statistics.new
					
					statistics.sample do
						response = client.get(request_path)
					end
					
					statistics.print
					client.close
				end
			end
			
			def invoke(parent)
				Async::Reactor.run do
					@hosts.each do |host|
						run(host).wait
					end
				end
			end
		end
	end
end
