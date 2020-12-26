# frozen_string_literal: true

require 'falcon/server'
require 'async/http/client'
require 'async/rspec/reactor'

require "async/http/client"
require "async/http/endpoint"

RSpec.shared_context Falcon::Server do
	include_context Async::RSpec::Reactor
	
	let(:protocol) {Async::HTTP::Protocol::HTTP1}
	let(:endpoint) {Async::HTTP::Endpoint.parse('http://127.0.0.1:9294', reuse_port: true)}
	let!(:client) {Async::HTTP::Client.new(endpoint, protocol: protocol)}
	
	let!(:server_task) do
		reactor.async do
			server.run
		end
	end
	
	after(:each) do
		server_task.stop
		client.close
	end
	
	let(:app) do
		lambda do |env|
			[200, {}, []]
		end
	end
	
	let(:middleware) do
		Falcon::Server.middleware(app)
	end
	
	let(:server) do
		Falcon::Server.new(middleware, endpoint, protocol: protocol)
	end
end
