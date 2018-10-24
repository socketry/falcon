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

hosts.call(controller)

Process.setproctitle("Falcon Controller")
controller.wait
