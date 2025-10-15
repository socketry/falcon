# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2025, by Samuel Williams.
# Copyright, 2019, by Sho Ito.

require "falcon/command/serve"

ServeCommand = Sus::Shared("falcon serve") do
	let(:command) do
		subject[
			"--port", port,
			"--config", File.expand_path("config.ru", __dir__), *options
		]
	end
	
	it "can listen on specified port" do
		configuration = command.configuration
		controller = configuration.controller
		
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
end
