# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "falcon/environment/cluster"
require "async/service/environment"

describe Falcon::Environment::Cluster do
	let(:evaluator) do
		Async::Service::Environment.build(subject, name: "localhost").evaluator
	end
	
	it "provides default cluster settings" do
		expect(evaluator).to have_attributes(
			service_class: be == Falcon::Service::Cluster,
			url: be == "http://[::]:0",
			authority: be == "localhost",
		)
	end
	
	it "prepares workers using the existing preparation hook" do
		instance = Object.new
		listener = Object.new
		
		expect(evaluator).to receive(:prepare!).with(instance)
		
		evaluator.prepare_worker!(instance, listener: listener)
	end
end
