# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2026, by Samuel Williams.

require "falcon/command"
require "sus/fixtures/console/captured_logger"

describe Falcon::Command::Top do
	include Sus::Fixtures::Console::CapturedLogger
	
	with "basic server configuration" do
		it "can listen on specified port" do
			top = subject[
				"--verbose",
				"serve",
				"--threaded",
				"--config", File.expand_path("config.ru", __dir__),
			]
			
			serve = top.command
			controller = serve.configuration.make_controller
			controller.start
			
			Async do
				client = serve.client
				
				response = client.get("/")
				expect(response).to be(:success?)
				
				response.finish
				client.close
			end
			
			controller.stop
		end
	end
	
	it "identifies quiet logging" do
		expect(subject["--quiet"]).to be(:quiet?)
	end
	
	it "prints the version" do
		top = subject["--version"]
		captured_message = nil
		
		mock(top) do |mock|
			mock.replace(:puts) do |message|
				captured_message = message
			end
		end
		
		top.call
		
		expect(captured_message).to be == "#{top.name} v#{Falcon::VERSION}"
	end
	
	it "prints usage" do
		top = subject["--help"]
		
		printed_usage = false
		
		mock(top) do |mock|
			mock.replace(:print_usage) do
				printed_usage = true
			end
		end
		
		top.call
		
		expect(printed_usage).to be == true
	end
	
	it "updates default encoding when no encoding is configured" do
		top = subject[]
		called = false
		captured_encoding = nil
		
		mock(top) do |mock|
			mock.replace(:encoding) do
				nil
			end
			
			mock.replace(:update_external_encoding!) do |encoding = Encoding::UTF_8|
				captured_encoding = encoding
			end
		end
		
		mock(top.command) do |command|
			command.replace(:call) do
				called = true
			end
		end
		
		top.call
		
		expect(called).to be == true
		expect(captured_encoding).to be == Encoding::UTF_8
	end
	
	it "updates the default external encoding" do
		top = subject[]
		captured_encoding = nil
		
		mock(Encoding) do |mock|
			mock.replace(:default_external) do
				Encoding::UTF_8
			end
			
			mock.replace(:default_external=) do |encoding|
				captured_encoding = encoding
			end
		end
		
		top.update_external_encoding!(Encoding::US_ASCII)
		
		expect_console.to have_logged(
			severity: be == :warn,
			subject: be == top,
			message: be(:include?, "Updating Encoding.default_external"),
		)
		
		expect(captured_encoding).to be == Encoding::US_ASCII
	end
end
