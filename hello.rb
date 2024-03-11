#!/usr/bin/env async-service

require 'falcon/service/server'

service "hello-server" do
	include Falcon::Service::Server
	
	middleware do
		::Protocol::HTTP::Middleware::HelloWorld
	end
end
