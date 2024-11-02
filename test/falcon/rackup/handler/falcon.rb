# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2024, by Samuel Williams.

require "sus/fixtures/async"

require "falcon/server"
require "async/http/endpoint"
require "async/http/client"
require "async/process"

require "rackup/handler/falcon"

RackupHandler = Sus::Shared("rackup handler") do |server_name|
	include Sus::Fixtures::Async::ReactorContext
	
	let(:config_path) {File.join(__dir__, "config.ru")}
	
	let(:endpoint) {Async::HTTP::Endpoint.parse("http://localhost:9290")}
	let(:client) {Async::HTTP::Client.new(endpoint)}
	
	it "can start rackup --server #{server_name}" do
		server_task = reactor.async do
			Async::Process.spawn("rackup", "--server", server_name, "--host", endpoint.hostname, "--port", endpoint.port.to_s, config_path)
		end
		
		response = nil
		
		# This mess is because there is no way to know when the above process is ready to handle connections...
		10.times do |i|
			begin
				response = client.post("/", {}, ["Hello World"])
			rescue Errno::ECONNREFUSED
				Async::Task.current.sleep(i/10.0)
				retry
			else
				break
			end
		end
		
		expect(response).to be(:success?)
		expect(response.read).to be == "Hello World"
		
		client.close
		server_task.stop
		server_task.wait
	end
end

describe Falcon::Rackup::Handler do
	it_behaves_like RackupHandler, "falcon"

	let(:app) {lambda {|env| [200, {}, ["Hello World"]]}}

	it "can start and stop server" do
		Rackup::Handler::Falcon.run(app) do |server|
			server.stop
		end
	end
end

