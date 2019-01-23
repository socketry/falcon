
namespace :benchmark do
	task :compare do
		require 'etc'
		
		require 'async/reactor'
		require 'async/process'
		require 'async/clock'
		require 'async/io/stream'
		require 'async/http/url_endpoint'
		
		host = "http://127.0.0.1:9292"
		config_path = File.expand_path("../examples/benchmark/config.ru", __dir__)
		
		threads = Etc.nprocessors
		
		perf = ["perf", "record", "-F", "max", "-a", "--"]
		
		servers = [
			# ["puma", "--bind", host.gsub("http", "tcp")],
			["puma", "--workers", threads.to_s, "--bind", host.gsub("http", "tcp")],
			# ["rbspy", "record", "--", "falcon", "serve", "--threaded", "--bind", host, "--config"]
			["falcon", "serve", "--bind", host, "--config"]
		]
		
		Async.logger.info!
		
		endpoint = Async::HTTP::URLEndpoint.parse(host)
		
		servers.each do |command|
			::Async::Reactor.run do |task|
				begin
					server_status = nil
					
					# This computes the startup time:
					start_time = Async::Clock.now
					
					server_task = task.async do
						$stderr.puts "Starting #{command.first}"
						server_status = Async::Process.spawn(*command, config_path)
					end
					
					begin
						unless server_status.nil?
							raise RuntimeError, "Server failed to start: #{server_status}"
						end
						
						socket = endpoint.connect
						
						request = Async::HTTP::Request.new("http", "localhost", "GET", "/big")
						stream = Async::IO::Stream.new(socket)
						protocol = Async::HTTP::Protocol::HTTP1.client(stream)
						
						response = protocol.call(request)
						
						Async.logger.info(response, "Headers:", response.headers.to_h) {"Response body size: #{response.read.bytesize}"}
						
						response.close
						
						socket.close
					rescue Errno::ECONNREFUSED, Errno::ECONNRESET
						task.sleep 0.01
						
						retry
					end
					
					end_time = Async::Clock.now
					
					Async.logger.info(command) {"** Took #{end_time - start_time}s to first response."}
					
					threads.times do |n|
						c = (2**n).to_s
						puts "Running #{command.first} with #{c} concurrent connections..."
						
						# Async::Process.spawn("curl", "-v", "#{host}/small")
						
						# Async::Process.spawn("ab", "-n", "2000", "#{host}/small")
						
						Async::Process.spawn("wrk", "-c", c.to_s, "-t", (n+1).to_s, "-d", "2", "#{host}/big")
					end
				ensure
					server_task.stop
				end
			end
		end
	end
end
