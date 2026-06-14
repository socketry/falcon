# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "falcon/environment/application"
require "falcon/proxy_endpoint"
require "async/service/environment"
require "sus/fixtures/temporary_directory_context"

describe Falcon::Environment::Application do
	include Sus::Fixtures::TemporaryDirectoryContext
	
	let(:evaluator) do
		Async::Service::Environment.build(subject, root: root, name: "localhost").evaluator
	end
	
	it "provides default middleware and application endpoint" do
		expect(evaluator).to have_attributes(
			middleware: be == Protocol::HTTP::Middleware::HelloWorld,
			ipc_path: be == File.join(root, "application.ipc"),
		)
		
		endpoint = evaluator.endpoint
		
		expect(endpoint).to be_a(Falcon::ProxyEndpoint)
		expect(endpoint).to have_attributes(
			scheme: be == "https",
			authority: be == "localhost",
		)
	end
end
