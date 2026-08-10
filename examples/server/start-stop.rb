#!/usr/bin/env ruby

require 'async'
require 'async/http/endpoint'
require 'falcon'

module App
	def self.call(env)
		Async::Task.current.sleep(10)
		
		return [200, [], ["Hello World"]]
	end
end

def start_server
	Async do
		endpoint = Async::HTTP::Endpoint.parse('http://127.0.0.1:3000')
		
		app = Falcon::Server.middleware(App)
		
		server = Falcon::Server.new(app, endpoint)
		
		server.run.each(&:wait)
	end
end

Async do |top|
	server_task = start_server
	
	while true
		top.print_hierarchy
		top.sleep(10)
	end
	
	server_task.wait
end
