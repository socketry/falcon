# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2023, by Samuel Williams.
# Copyright, 2020, by Tasos Latsas.

require 'falcon/server'
require 'async/http/client'
require 'async/http/endpoint'
require 'async/rspec/reactor'
require 'async/rspec/ssl'

require 'async/io/ssl_socket'
require 'async/io/shared_endpoint'

RSpec.describe "Falcon::Server with SSL", timeout: 10 do
	include_context Async::RSpec::Reactor
	
	include_context Async::RSpec::SSL::ValidCertificate
	include_context Async::RSpec::SSL::VerifiedContexts
	
	let(:protocol) {Async::HTTP::Protocol::HTTPS}
	
	let(:server_endpoint) {Async::HTTP::Endpoint.parse("https://localhost:6365", ssl_context: server_context)}
	let(:bound_endpoint) {Async::IO::SharedEndpoint.bound(server_endpoint)}
	let(:client_endpoint) {Async::HTTP::Endpoint.parse("https://localhost:6365", ssl_context: client_context)}
	
	let(:server) {Falcon::Server.new(Protocol::Rack::Adapter.new(app), bound_endpoint, protocol: protocol, scheme: server_endpoint.scheme)}
	let(:client) {Async::HTTP::Client.new(client_endpoint, protocol: protocol)}
	after(:each) {client.close}
	
	around(:each) do |example|
		bound_endpoint
		
		server_task = reactor.async do
			server.run
		end
		
		begin
			example.run
		ensure
			bound_endpoint.close
			server_task.stop
		end
	end
	
	context "basic middleware" do
		let(:app) do
			lambda do |env|
				[200, {}, ["Hello World"]]
			end
		end
		
		it "client can get resource" do
			response = client.get("/", {})
			
			expect(response).to be_success
			expect(response.read).to be == "Hello World"
		end
	end
end
