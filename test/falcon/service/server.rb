# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024, by Samuel Williams.

require 'falcon/service/server'
require 'falcon/configuration'
require 'falcon/environment/server'
require 'falcon/environment/rackup'

describe Falcon::Service::Server do
	let(:environment) do
		Async::Service::Environment.new(Falcon::Environment::Server).with(
			Falcon::Environment::Rackup,
			name: 'hello',
			root: File.expand_path('.server/hello', __dir__),
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
		
		expect(container.group.running).to have_attributes(size: be > 0)
		
		server.stop
		container.stop
	end
	
	with 'a limited count' do
		let(:environment) do
			Async::Service::Environment.new(Falcon::Environment::Server).with(
				Falcon::Environment::Rackup,
				name: 'hello',
				root: File.expand_path('.server/hello', __dir__),
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
end
