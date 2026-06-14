# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "falcon/command/redirect"
require "sus/fixtures/console/captured_logger"

describe Falcon::Command::Redirect do
	include Sus::Fixtures::Console::CapturedLogger
	
	let(:command) do
		subject[
			"--bind", "http://localhost:8095",
			"--redirect", "https://localhost:8495",
			"--timeout", "1",
		]
	end
	
	it "builds endpoint helpers" do
		expect(command.endpoint).to be_a(Async::HTTP::Endpoint)
		expect(command.redirect_endpoint).to be_a(Async::HTTP::Endpoint)
	end
	
	it "logs resolved paths when running" do
		command = subject[
			"--bind", "http://localhost:8095",
			"--redirect", "https://localhost:8495",
			"test/falcon/command/config.ru",
		]
		
		expect(command).to receive(:configuration).and_return(Async::Service::Configuration.new)
		captured_configuration = nil
		
		mock(Async::Service::Controller) do |controller|
			controller.replace(:run) do |configuration|
				captured_configuration = configuration
			end
		end
		
		command.call
		
		expect(captured_configuration).to be_a(Async::Service::Configuration)
		
		expect_console.to have_logged(
			severity: be == :info,
			subject: be == command,
			message: be(:include?, "Loading configuration from test/falcon/command/config.ru"),
		)
	end
	
	it "runs the controller" do
		captured_configuration = nil
		
		mock(Async::Service::Controller) do |controller|
			controller.replace(:run) do |configuration|
				captured_configuration = configuration
			end
		end
		
		command.call
		
		expect(captured_configuration).to be_a(Async::Service::Configuration)
		
		expect_console.to have_logged(
			severity: be == :info,
			subject: be == command,
			message: be(:include?, "Falcon Redirect v"),
		)
	end
end
