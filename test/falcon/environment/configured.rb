# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "falcon/environment/configured"
require "async/service/configuration"
require "async/service/environment"

describe Falcon::Environment::Configured do
	let(:evaluator) do
		Async::Service::Environment.build(subject).evaluator
	end
	
	it "provides default configuration paths" do
		expect(evaluator.configuration_paths).to be == ["/srv/http/*/falcon.rb"]
	end
	
	it "expands configured paths" do
		expect(evaluator.resolved_configuration_paths).to be == []
	end
	
	it "loads resolved configuration paths" do
		expect(Async::Service::Configuration).to receive(:load).with([]).and_return(:configuration)
		
		expect(evaluator.configuration).to be == :configuration
	end
end
