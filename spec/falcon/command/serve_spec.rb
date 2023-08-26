# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2021, by Samuel Williams.
# Copyright, 2019, by Sho Ito.

require 'falcon/command/serve'

RSpec.shared_examples_for Falcon::Command::Serve do
	let(:command) do
		described_class[
			"--port", port,
			"--config", File.expand_path("config.ru", __dir__), *options
		]
	end
	
	it "can listen on specified port" do
		controller = command.controller
		
		controller.start
		
		begin
			Async do
				client = command.client
				
				response = client.get("/")
				expect(response).to be_success
				
				response.finish
				client.close
			end
		ensure
			controller.stop
		end
	end
end

RSpec.describe Falcon::Command::Serve do
	let(:options) { [] }

	context "with custom port" do
		let(:port) {8090}
		include_examples Falcon::Command::Serve
	end
	
	context "with one instance" do
		let(:port) {8091}
		let(:options) {["--count", 1]}
		include_examples Falcon::Command::Serve
	end
	
	context "with threaded container" do
		let(:port) {8092}
		let(:options) {["--count", 4, "--threaded"]}
		include_examples Falcon::Command::Serve
	end
	
	context "with forked container", if: Process.respond_to?(:fork) do
		let(:port) {8093}
		let(:options) {["--count", 4, "--forked"]}
		include_examples Falcon::Command::Serve
	end
end
