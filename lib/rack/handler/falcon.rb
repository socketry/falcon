
require 'rack/handler'

require_relative '../../falcon'

module Rack
	module Handler
		module Falcon
			def self.run(app, **options)
				command = ::Falcon::Command::Serve.new([])
				
				process_count = command.options[:process]
				
				pids = process_count.times.collect do
					fork do
						puts "Serving from pid #{Process.pid}"
						command.run(app, options)
					end
				end
				
				sleep
			ensure
				pids.each do |pid|
					Process.kill(:TERM, pid) rescue nil
					Process.wait(pid)
				end
			end
			
			def self.valid_options
				{
					"host=HOST" => "Hostname to listen on (default: localhost)",
					"port=PORT" => "Port to listen on (default: 8080)",
					"verbose" => "Don't report each request (default: false)"
				}
			end
		end
		
		register :falcon, Falcon
	end
end
