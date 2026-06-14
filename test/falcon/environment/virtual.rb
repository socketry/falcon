# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "falcon/environment/virtual"
require "async/service/environment"

describe Falcon::Environment::Virtual do
	let(:evaluator) do
		Async::Service::Environment.build(subject).evaluator
	end
	
	it "provides default virtual host settings" do
		expect(evaluator).to have_attributes(
			name: be == "Falcon::Service::Virtual",
			bind_secure: be == "https://[::]:443",
			bind_insecure: be == "http://[::]:80",
			timeout: be == 10.0,
			falcon_path: be == File.expand_path("../../../bin/falcon", __dir__),
		)
	end
end
