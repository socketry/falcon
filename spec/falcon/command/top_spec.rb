# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2020, by Samuel Williams.

require 'falcon/command'

RSpec.describe Falcon::Command::Top do
	context "basic server" do
		it "can listen on specified port" do
			top = described_class[
				"--verbose",
				"serve",
				"--threaded",
				"--config", File.expand_path("config.ru", __dir__),
			]
			
			serve = top.command
			container = serve.controller
			container.start
			
			Async do
				client = serve.client
				
				response = client.get("/")
				expect(response).to be_success
				
				response.finish
				client.close
			end
			
			container.stop
		end
	end
end
