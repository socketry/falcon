# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024, by Samuel Williams.

require "falcon/configuration"
require "falcon/environment/supervisor"

require "temporary_directory_context"

describe Falcon::Environment::Supervisor do
	include TemporaryDirectoryContext
	
	let(:environment) do
		Async::Service::Environment.new(Falcon::Environment::Supervisor).with(
			root: @root,
		)
	end
	
	let(:supervisor) do
		environment.evaluator.service_class.new(environment)
	end
	
	it "can start and stop server" do
		container = Async::Container.new
		
		supervisor.start
		supervisor.setup(container)
		container.wait_until_ready
		
		expect(container.group.running).to have_attributes(size: be == 1)
		
		Sync do
			client = Async::Container::Supervisor::Client.new(endpoint: environment.evaluator.endpoint)
			client.connect do |connection|
				response = connection.call(do: "status")
				
				expect(response).to be_a(Array)
				expect(response.size).to be == 1
				
				first = response.first
				expect(first).to have_keys(
					memory_monitor: be_a(Hash),
				)
			end
		end
	ensure
		supervisor.stop
		container.stop
	end
end
