# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2026, by Samuel Williams.
# Copyright, 2019, by Sho Ito.

require "falcon/command/serve"
require "sus/fixtures/console/captured_logger"
require "sus/fixtures/async/scheduler_context"

ServeCommand = Sus::Shared("falcon serve") do
	include Sus::Fixtures::Async::SchedulerContext
	
	let(:command) do
		subject[
			"--port", port,
			"--config", File.expand_path("config.ru", __dir__), *options
		]
	end
	
	it "can listen on specified port" do
		configuration = command.configuration
		controller = configuration.make_controller
		
		controller.start
		
		begin
			Async do
				client = command.client
				
				response = client.get("/")
				expect(response).to be(:success?)
				
				response.finish
				client.close
			end
		ensure
			controller.stop
		end
	end
end

describe Falcon::Command::Serve do
	include Sus::Fixtures::Console::CapturedLogger
	
	let(:options) {[]}
	
	with "custom port" do
		let(:port) {8090}
		it_behaves_like ServeCommand
	end
	
	with "one instance" do
		let(:port) {8091}
		let(:options) {["--count", 1]}
		it_behaves_like ServeCommand
	end
	
	with "threaded container" do
		let(:port) {8092}
		let(:options) {["--count", 4, "--threaded"]}
		it_behaves_like ServeCommand
	end
	
	with "forked container", if: Process.respond_to?(:fork) do
		let(:port) {8093}
		let(:options) {["--count", 4, "--forked"]}
		it_behaves_like ServeCommand
	end
	
	with "hybrid container" do
		let(:port) {8094}
		let(:options) {["--count", 4, "--hybrid", "--forks", 2, "--threads", 2]}
		
		it "uses the hybrid container class and exposes endpoint helpers" do
			command = subject[
				"--port", port,
				"--config", File.expand_path("config.ru", __dir__),
				*options
			]
			
			expect(command.container_class).to be == Async::Container::Hybrid
			expect(command.endpoint).to be_a(Falcon::Endpoint)
			expect(command.client_endpoint).to be_a(Async::HTTP::Endpoint)
		end
	end
	
	it "selects container classes" do
		expect(subject["--threaded"].container_class).to be == Async::Container::Threaded
		expect(subject["--forked"].container_class).to be == Async::Container::Forked
		expect(subject["--hybrid"].container_class).to be == Async::Container::Hybrid
	end
	
	it "runs the controller" do
		command = subject[
			"--port", 8095,
			"--config", File.expand_path("config.ru", __dir__),
			"--threaded",
		]
		
		captured_configuration = nil
		captured_container_class = nil
		captured_graceful_stop = nil
		
		mock(Async::Service::Controller) do |controller|
			controller.replace(:run) do |configuration, container_class:, graceful_stop:|
				captured_configuration = configuration
				captured_container_class = container_class
				captured_graceful_stop = graceful_stop
			end
		end
		
		command.call
		
		expect(captured_configuration).to be_a(Async::Service::Configuration)
		expect(captured_container_class).to be == Async::Container::Threaded
		expect(captured_graceful_stop).to be == 1.0
		
		expect_console.to have_logged(
			severity: be == :info,
			subject: be == command,
			message: be(:include?, "Falcon v"),
		)
	end
end
