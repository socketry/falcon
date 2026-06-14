# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "falcon/environment/redirect"
require "async/service/environment"

describe Falcon::Environment::Redirect do
	let(:evaluator) do
		Async::Service::Environment.build(subject).evaluator
	end
	
	it "provides default redirect settings" do
		expect(evaluator).to have_attributes(
			redirect_url: be == "https://[::]:443",
			environments: be == [],
		)
		expect(evaluator.redirect_endpoint).to be_a(Async::HTTP::Endpoint)
	end
end
