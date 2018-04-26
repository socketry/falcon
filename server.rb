#!/usr/bin/env falcon serve

require 'falcon'
require 'async/container/controller'
require 'async/container/forked'

hosts = Falcon::Configuration::Hosts.new

hosts.add('mc.oriontransfer.co.nz') do |host|
	host.endpoint = Async::IO::URLEndpoint.parse('http://localhost:6000')
	
	host.ssl_certificate_path = '/etc/letsencrypt/live/mc.oriontransfer.co.nz/fullchain.pem'
	host.ssl_key_path = '/etc/letsencrypt/live/mc.oriontransfer.co.nz/privkey.pem'
end

hosts.add('chick.nz') do |host|
	host.endpoint = Async::IO::URLEndpoint.parse('http://localhost:8765')
	
	host.ssl_certificate_path = '/etc/letsencrypt/live/chick.nz/fullchain.pem'
	host.ssl_key_path = '/etc/letsencrypt/live/chick.nz/privkey.pem'
end

controller = Async::Container::Controller.new

hosts.each do |name, host|
	if container = host.start
		controller << container
	end
end

proxy = Falcon::Proxy.new(Falcon::BadRequest, hosts.client_endpoints)

controller << Async::Container::Forked.new do
	server = Falcon::Server.new(proxy, hosts.endpoint)
	
	server.run
end

controller.wait
