# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024, by Samuel Williams.

require "falcon/service/server"
require "falcon/configuration"
require "falcon/environment/server"
require "falcon/environment/rackup"

describe Falcon::Service::Server do
	let(:environment) do
		Async::Service::Environment.new(Falcon::Environment::Server).with(
			Falcon::Environment::Rackup,
			name: "hello",
			root: File.expand_path(".server/hello", __dir__),
			url: "http://localhost:0",
		)
	end
	
	let(:server) do
		subject.new(environment)
	end
	
	it "can create a server" do
		expect(server).to be_a subject
	end
	
	it "can start and stop server" do
		container = Async::Container.new
		
		server.start
		server.setup(container)
		container.wait_until_ready
		
		expect(container.group.running).to have_attributes(size: be == Etc.nprocessors)
		
		server.stop
		container.stop
	end
	
	with "a limited count" do
		let(:environment) do
			Async::Service::Environment.new(Falcon::Environment::Server).with(
				Falcon::Environment::Rackup,
				name: "hello",
				root: File.expand_path(".server/hello", __dir__),
				url: "http://localhost:0",
				count: 1,
			)
		end
		
		it "can start and stop server" do
			container = Async::Container.new
			
			server.start
			server.setup(container)
			container.wait_until_ready
			
			expect(container.group.running).to have_attributes(size: be == 1)
			
			server.stop
			container.stop
		end
	end
	
	with "legacy make_supervised_worker" do
		let(:instance) {Object.new}
		
		let(:supervised_worker) do
			worker = Object.new
			def worker.run
				# Mock method - will be stubbed by expect
			end
			worker
		end
		
		let(:mock_server) do
			server = Object.new
			def server.run
				# Mock method - will be stubbed by expect
			end
			server
		end
		
		it "invokes make_supervised_worker when evaluator responds to it" do
			server.start
			
			evaluator = environment.evaluator
			
			# Verify make_supervised_worker is called with the instance and returns supervised_worker
			expect(evaluator).to receive(:make_supervised_worker).with(instance).and_return(supervised_worker)
			
			# Verify supervised_worker.run is called
			expect(supervised_worker).to receive(:run)
			
			# Mock make_server to return our mock server
			expect(evaluator).to receive(:make_server).and_return(mock_server)
			
			# Mock server.run to avoid errors in the Async block
			expect(mock_server).to receive(:run)
			
			Async do
				result = server.run(instance, evaluator)
				expect(result).to be == mock_server
			end.wait
			
			server.stop
		end
	end
end
