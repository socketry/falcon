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
	
	let(:bound_endpoints) do
		endpoints.map{|endpoint| Sync{endpoint.bound}}
	end
	
	let(:servers) do
		bound_endpoints.map.with_index do |bound_endpoint, index|
			# Mock the endpoint to add protocol and scheme
			mock(bound_endpoint) do |wrapper|
				wrapper.replace(:protocol) {Async::HTTP::Protocol::HTTP1}
				wrapper.replace(:scheme) {"http"}
			end
			
			["server#{index + 1}", Falcon::Server.new(middleware, bound_endpoint)]
		end.to_h
	end
	
	let(:composite_server) do
		subject.new(servers)
	end
	
	def after(...)
		bound_endpoints.each(&:close)
		super
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
		
		Async do |task|
			server_task = task.async do
				composite_server.run
			end
			
			# Give servers time to start
			task.sleep(0.1)
			
			# Make requests to both servers
			bound_endpoints.each do |bound_endpoint|
				client_endpoint = bound_endpoint.local_address_endpoint
				
				mock(client_endpoint) do |wrapper|
					wrapper.replace(:protocol) {Async::HTTP::Protocol::HTTP1}
					wrapper.replace(:scheme) {"http"}
				end
				
				client = ::Async::HTTP::Client.new(client_endpoint)
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
	end
	
	it "can stop all servers" do
		Async do |task|
			server_task = task.async do
				composite_server.run
			end
			
			# Give servers time to start
			task.sleep(0.1)
			
			# Stop the composite server by stopping the returned task
			server_task.stop
			
			# Give time for cleanup
			task.sleep(0.1)
			
			# The server task should be stopped
			expect(server_task).to be(:stopped?)
		end
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
			expect(statistics).to be == "No servers running"
		end
	end
	
	with "single server" do
		let(:servers) do
			bound_endpoint = bound_endpoints.first
			
			# Mock the endpoint to add protocol and scheme
			mock(bound_endpoint) do |wrapper|
				wrapper.replace(:protocol) {Async::HTTP::Protocol::HTTP1}
				wrapper.replace(:scheme) {"http"}
			end
			
			{"main" => Falcon::Server.new(middleware, bound_endpoint)}
		end
		
		it "manages a single server" do
			expect(composite_server.servers).to have_attributes(size: be == 1)
			
			statistics = composite_server.statistics_string
			expect(statistics).to be =~ /main:/
		end
	end
end
