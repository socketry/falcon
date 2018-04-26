#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path('lib', __dir__)

require 'falcon'
require 'async/http/url_endpoint'
require 'async/container/controller'
require 'async/container/forked'

Async.logger.level = Logger::INFO

hosts = Falcon::Hosts.new

hosts.add('map.local') do |host|
	host.endpoint = Async::HTTP::URLEndpoint.parse('http://hana.local:8123')
	
	# host.ssl_certificate_path = '/etc/letsencrypt/live/mc.oriontransfer.co.nz/fullchain.pem'
	# host.ssl_key_path = '/etc/letsencrypt/live/mc.oriontransfer.co.nz/privkey.pem'
end

hosts.add('chick.local') do |host|
	host.endpoint = Async::HTTP::URLEndpoint.parse('http://hana.local:8765')
	
	# host.ssl_certificate_path = '/etc/letsencrypt/live/chick.nz/fullchain.pem'
	# host.ssl_key_path = '/etc/letsencrypt/live/chick.nz/privkey.pem'
end

controller = Async::Container::Controller.new

hosts.each do |name, host|
	if container = host.start
		controller << container
	end
end

proxy = Falcon::Verbose.new(
	proxy = Falcon::Proxy.new(Falcon::BadRequest, hosts.client_endpoints)
)

controller << Async::Container::Forked.new do
	Process.setproctitle("Falcon Proxy")
	
	server = Falcon::Server.new(proxy, Async::HTTP::URLEndpoint.parse(
		'http://0.0.0.0:4433',
		reuse_address: true
	))
	
	server.run
end

Process.setproctitle("Falcon Controller")
controller.wait
