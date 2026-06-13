# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "falcon/command/host"
require "sus/fixtures/console/captured_logger"

describe Falcon::Command::Host do
	include Sus::Fixtures::Console::CapturedLogger
	
	let(:command) do
		subject[]
	end
	
	it "runs the controller" do
		captured_configuration = nil
		captured_container_class = nil
		
		mock(Async::Service::Controller) do |controller|
			controller.replace(:run) do |configuration, container_class:|
				captured_configuration = configuration
				captured_container_class = container_class
			end
		end
		
		command.call
		
		expect(captured_configuration).to be_a(Async::Service::Configuration)
		expect(captured_container_class).to be == command.container_class
		
		expect_console.to have_logged(
			severity: be == :info,
			subject: be == command,
			message: be(:include?, "Falcon Host v"),
		)
	end
	
	it "reports errors from the host entry point" do
		error = RuntimeError.new("boom")
		captured_status = nil
		
		mock(Async::Service::Controller) do |controller|
			controller.replace(:run) do |configuration, container_class:|
				raise error
			end
		end
		
		mock(subject) do |host|
			host.replace(:exit!) do |status|
				captured_status = status
			end
		end
		
		subject.call(["missing.rb"])
		
		expect(captured_status).to be == 1
		
		expect_console.to have_logged(
			severity: be == :error,
			subject: be == subject,
			arguments: be == [error],
			message: be == "boom",
		)
	end
end
