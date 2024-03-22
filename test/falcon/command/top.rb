# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2023, by Samuel Williams.

require 'falcon/command'

describe Falcon::Command::Top do
	with "basic server configuration" do
		it "can listen on specified port" do
			top = subject[
				"--verbose",
				"serve",
				"--threaded",
				"--config", File.expand_path("config.ru", __dir__),
			]
			
			serve = top.command
			controller = serve.configuration.controller
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
end
