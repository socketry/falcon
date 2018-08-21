#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path('lib', __dir__)

require 'falcon'
require 'async/http/url_endpoint'
require 'async/container/controller'
require 'async/container/forked'

require 'async/clock'
require 'ruby-prof'

Async.logger.level = Logger::INFO

hosts = Falcon::Hosts.new

hosts.add('mc.oriontransfer.co.nz') do |host|
	host.endpoint = Async::HTTP::URLEndpoint.parse('http://hana.local:8123')
	
	host.ssl_certificate_path = '/etc/letsencrypt/live/mc.oriontransfer.co.nz/fullchain.pem'
	host.ssl_key_path = '/etc/letsencrypt/live/mc.oriontransfer.co.nz/privkey.pem'
end

hosts.add('chick.nz') do |host|
	host.endpoint = Async::HTTP::URLEndpoint.parse('http://hana.local:8765')
	
	host.ssl_certificate_path = '/etc/letsencrypt/live/chick.nz/fullchain.pem'
	host.ssl_key_path = '/etc/letsencrypt/live/chick.nz/privkey.pem'
end

controller = Async::Container::Controller.new

hosts.each do |name, host|
	if container = host.start
		controller << container
	end
end

proxy = hosts.proxy
debug_trap = Async::IO::Trap.new(:USR1)

profile = RubyProf::Profile.new(merge_fibers: true)

#controller << Async::Container::Forked.new do |task|
	Process.setproctitle("Falcon Proxy")
	
	server = Falcon::Server.new(
		proxy,
		Async::HTTP::URLEndpoint.parse(
			'https://0.0.0.0',
			reuse_address: true,
			ssl_context: hosts.ssl_context
		)
	)

begin
	#profile.start
	
	Async::Reactor.run do |task|
		task.async do
			debug_trap.install!
			$stderr.puts "Send `kill -USR1 #{Process.pid}` for detailed status :)"
			
			debug_trap.trap do
				task.reactor.print_hierarchy($stderr)
				# Async.logger.level = Logger::DEBUG
			end
		end
		
		task.async do |task|
			start_time = Async::Clock.now
			
			while true
				task.sleep(600)
				duration = Async::Clock.now - start_time
				puts "Handled #{proxy.count} requests; #{(proxy.count.to_f / duration.to_f).round(1)} requests per second."
			end
		end
		
		$stderr.puts "Starting server"
		server.run
	end
ensure
	if profile.running?
		profile.stop
		
		# print a flat profile to text
		printer = RubyProf::FlatPrinter.new(profile)
		printer.print($stdout)
	end
end

#Process.setproctitle("Falcon Controller")
#controller.wait

