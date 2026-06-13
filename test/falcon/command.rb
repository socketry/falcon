# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "falcon/command"
require "sus/fixtures/console/captured_logger"

describe Falcon::Command do
	include Sus::Fixtures::Console::CapturedLogger
	
	it "reports errors from the command entry point" do
		error = RuntimeError.new("boom")
		captured_status = nil
		
		mock(Falcon::Command::Top) do |top|
			top.replace(:call) do
				raise error
			end
		end
		
		mock(subject) do |command|
			command.replace(:exit!) do |status|
				captured_status = status
			end
		end
		
		subject.call
		
		expect(captured_status).to be == 1
		
		expect_console.to have_logged(
			severity: be == :error,
			subject: be == subject,
			arguments: be == [error],
			message: be == "boom",
		)
	end
end
