# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "falcon/environment/proxy"
require "async/service/environment"
require "sus/fixtures/console/captured_logger"

describe Falcon::Environment::Proxy do
	include Sus::Fixtures::Console::CapturedLogger
	
	let(:evaluator) do
		Async::Service::Environment.build(subject).evaluator
	end
	
	it "provides default proxy settings" do
		expect(evaluator).to have_attributes(
			url: be == "https://[::]:443",
			environments: be == [],
		)
	end
	
	it "returns nil for unknown host contexts" do
		socket = Object.new
		
		expect(evaluator.host_context(socket, "missing.localhost")).to be == nil
		
		expect_console.to have_logged(
			severity: be == :warn,
			subject: be == evaluator,
			message: be(:include?, "Unable to resolve missing.localhost"),
		)
	end
end
