# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2022, by Samuel Williams.
# Copyright, 2019, by Bryan Powell.

require 'async/http/server'
require 'async/http/client'
require 'async/http/endpoint'
require 'async/io/shared_endpoint'

require 'falcon/server'

RSpec.shared_context Falcon::Server do
	include_context Async::RSpec::Reactor
	
	let(:protocol) {Async::HTTP::Protocol::HTTP1}
	let(:endpoint) {Async::HTTP::Endpoint.parse('http://127.0.0.1:9294', timeout: 0.8, reuse_port: true, protocol: protocol)}
	
	let(:retries) {1}
	
	let(:middleware) do
		Falcon::Server.middleware(app)
	end
	
	let(:server) do
		Falcon::Server.new(middleware, @bound_endpoint)
	end
	
	before do
		@client = Async::HTTP::Client.new(endpoint, protocol: endpoint.protocol, retries: retries)
		
		# We bind the endpoint before running the server so that we know incoming connections will be accepted:
		@bound_endpoint = Async::IO::SharedEndpoint.bound(endpoint)
		
		# I feel a dedicated class might be better than this hack:
		allow(@bound_endpoint).to receive(:protocol).and_return(endpoint.protocol)
		allow(@bound_endpoint).to receive(:scheme).and_return(endpoint.scheme)
		
		@server_task = Async do
			server.run
		end
	end
	
	after do
		@client.close
		@server_task.stop
		@bound_endpoint.close
	end
	
	let(:client) {@client}
end
