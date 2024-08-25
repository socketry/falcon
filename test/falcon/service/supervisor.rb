# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024, by Samuel Williams.

require 'falcon/service/supervisor'
require 'falcon/configuration'
require 'falcon/environment/supervisor'

require 'temporary_directory_context'

describe Falcon::Service::Supervisor do
	include TemporaryDirectoryContext
	
	let(:environment) do
		Async::Service::Environment.new(Falcon::Environment::Supervisor).with(
			root: @root,
		)
	end
	
	let(:supervisor) do
		subject.new(environment)
	end
	
	it "can create a supervisor" do
		expect(supervisor).to be_a subject
	end
	
	it "can start and stop server" do
		container = Async::Container.new
		
		supervisor.start
		supervisor.setup(container)
		container.wait_until_ready
		
		expect(container.group.running).to have_attributes(size: be == 1)
		
		response = supervisor.invoke({please: 'metrics'})
		
		expect(response).to be_a(Hash)
		
		# The supervisor should report itself:
		expect(response.values).to have_value(have_keys(
			command: be == "supervisor"
		))
	ensure
		supervisor.stop
		container.stop
	end
end
