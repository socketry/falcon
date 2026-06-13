# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "falcon/environment/server"
require "async/service/environment"

describe Falcon::Environment::Server do
	let(:evaluator) do
		Async::Service::Environment.build(subject, name: "localhost").evaluator
	end
	
	it "provides default server settings" do
		expect(evaluator).to have_attributes(
			url: be == "http://[::]:9292",
			authority: be == "localhost",
			timeout: be == nil,
			verbose: be == false,
			cache: be == false,
		)
		expect(evaluator.client_endpoint).to be_a(Async::HTTP::Endpoint)
	end
end
