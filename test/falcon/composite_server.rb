# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

require "falcon/composite_server"
require "falcon/server"
require "async/http/client"
require "async/http/endpoint"
require "protocol/http/middleware"
require "sus/fixtures/async"

describe Falcon::CompositeServer do
	include Sus::Fixtures::Async::ReactorContext
	
	let(:app) do
		lambda do |env|
			[200, {"content-type" => "text/plain"}, ["Hello from port #{env['SERVER_PORT']}"]]
		end
	end
	
	let(:middleware) do
		::Protocol::Rack::Adapter.new(app)
	end
	
	let(:endpoints) do
		[
			::Async::HTTP::Endpoint.parse("http://localhost:0", reuse_port: true),
			::Async::HTTP::Endpoint.parse("http://localhost:0", reuse_port: true),
		]
	end
	
	before do
		@bound_endpoints = endpoints.map{|endpoint| Sync{endpoint.bound}}
	end
	
	after do
		@bound_endpoints.each(&:close)
	end
	
	let(:servers) do
		@bound_endpoints.map.with_index do |bound_endpoint, index|
			["server#{index + 1}", Falcon::Server.new(middleware, bound_endpoint, protocol: Async::HTTP::Protocol::HTTP1, scheme: "http")]
		end.to_h
	end
	
	let(:composite_server) do
		subject.new(servers)
	end
	
	it "manages multiple server instances" do
		expect(composite_server.servers).to have_attributes(size: be == 2)
		
		# Verify they are all Falcon::Server instances
		composite_server.servers.each do |name, server|
			expect(name).to be_a(String)
			expect(server).to be_a(Falcon::Server)
		end
	end
	
	it "can handle requests on multiple endpoints" do
		clients = []
		
		server_task = Async do
			composite_server.run
		end
		
		# Make requests to both servers
		@bound_endpoints.each do |bound_endpoint|
			client_endpoint = bound_endpoint.local_address_endpoint.each.first
			
			client = ::Async::HTTP::Client.new(client_endpoint, protocol: Async::HTTP::Protocol::HTTP1, scheme: "http", authority: "localhost")
			clients << client
			
			# Make a request
			response = client.get("/")
			expect(response).to be(:success?)
			expect(response.read).to be =~ /Hello from port/
		end
		
		server_task.stop
	ensure
		clients.each(&:close)
	end
	
	it "can stop all servers" do
		server_task = Async do
			composite_server.run
		end
		
		# Give servers time to start
		sleep(0.1)
		
		# Stop the composite server by stopping the returned task
		server_task.stop
		
		server_task.wait_all
		
		# The server task should no longer be running:
		expect(server_task).not.to be(:running?)
	end
	
	it "provides statistics for each server" do
		statistics = composite_server.statistics_string
		expect(statistics).to be =~ /server1:/
		expect(statistics).to be =~ /server2:/
	end
	
	it "provides detailed statistics" do
		detailed_stats = composite_server.detailed_statistics
		expect(detailed_stats).to have_attributes(size: be == 2)
		
		detailed_stats.each do |name, stats|
			expect(name).to be_a(String)
			expect(stats).to be_a(String)
		end
	end
	
	with "empty server list" do
		let(:servers) do
			{}
		end
		
		it "reports no servers running" do
			statistics = composite_server.statistics_string
			expect(statistics).to be == ""
		end
	end
	
	with "single server" do
		let(:servers) do
			bound_endpoint = @bound_endpoints.first
			
			{"main" => Falcon::Server.new(middleware, bound_endpoint, protocol: Async::HTTP::Protocol::HTTP1, scheme: "http")}
		end
		
		it "manages a single server" do
			expect(composite_server.servers).to have_attributes(size: be == 1)
			
			statistics = composite_server.statistics_string
			expect(statistics).to be =~ /main:/
		end
	end
end
