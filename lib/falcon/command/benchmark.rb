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
			def initialize(concurrency)
				@samples = []
				@duration = 0
				
				@concurrency = concurrency
			end
			
			attr :samples
			attr :duration
			
			attr :concurrency
			
			def sequential_duration
				@duration / @concurrency
			end
			
			def count
				@samples.count
			end
			
			def per_second
				@samples.count.to_f / sequential_duration.to_f
			end
			
			def latency
				@duration.to_f / @samples.count.to_f
			end
			
			def similar?(other, difference = 1.1)
				ratio = other.latency / self.latency
				
				return ratio < difference
			end
			
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
					Math.sqrt(variance.abs)
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
				
				duration = Time.now - start_time
				@samples << duration
				@duration += duration
				
				return result
			end
			
			def sample(&block)
				# warmup
				yield
				
				begin
					measure(&block)
				end until confident?
			end
			
			def print(out = STDOUT)
				out.puts "#{@samples.count} samples. #{1.0 / self.average} per second. S/D: #{standard_deviation}."
			end
			
			private
			
			def confident?
				(@samples.count > @concurrency * 10) && @duration > (self.latency * 100)
			end
		end
		
		class Benchmark < Samovar::Command
			self.description = "Benchmark an HTTP server."
			
			many :hosts
			
			def measure_performance(concurrency, endpoint, request_path)
				puts "I am running #{concurrency} asynchronous tasks that will each make sequential requests..."
				
				statistics = Statistics.new(concurrency)
				task = Async::Task.current
				
				concurrency.times.map do
					task.async do
						client = Async::HTTP::Client.new(endpoint, endpoint.protocol)
						
						statistics.sample do
							response = client.get(request_path)
						end
						
						client.close
					end
				end.each(&:wait)
				
				puts "I made #{statistics.count} requests in #{statistics.duration.round(1)} seconds. That's #{statistics.per_second} asynchronous requests/second."
				
				return statistics
			end
			
			def run(url)
				endpoint = Async::HTTP::URLEndpoint.parse(url)
				request_path = endpoint.url.request_uri
				
				puts "I am going to benchmark #{url}..."
				
				Async::Reactor.run do |task|
					statistics = []
					minimum = 1
					
					base = measure_performance(minimum, endpoint, request_path)
					statistics << base
					
					current = 2
					maximum = nil
					
					while true
						results = measure_performance(current, endpoint, request_path)
						
						if base.similar?(results)
							statistics << results
							
							minimum = current
							current *= 2
						else
							maximum = current
							
							current = (minimum + (maximum - minimum) / 2).floor
							
							break if statistics.last.concurrency >= current
						end
					end
					
					puts "Your server can handle #{statistics.last.concurrency} concurrent requests."
				end
			end
			
			def invoke(parent)
				@hosts.each do |host|
					run(host).wait
				end
			end
		end
	end
end
