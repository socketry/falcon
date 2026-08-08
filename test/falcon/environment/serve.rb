# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "falcon/environment/serve"
require "falcon/environment/server"
require "async/service/environment"
require "sus/fixtures/temporary_directory_context"
require "fileutils"

describe Falcon::Environment::Serve do
	include Sus::Fixtures::TemporaryDirectoryContext
	
	let(:evaluator) do
		Async::Service::Environment.build(
			Falcon::Environment::Server,
			subject,
			root: root,
			name: "localhost",
		).evaluator
	end
	
	it "prefers config/serve.rb" do
		FileUtils.mkdir_p(File.join(root, "config"))
		File.write(File.join(root, "config.ru"), "run ->(env) {[200, {}, []]}\n")
		File.write(File.join(root, "config/serve.rb"), "run Protocol::HTTP::Middleware::Okay\n")
		
		expect(evaluator.resolved_configuration_path).to be == File.join(root, "config/serve.rb")
	end
	
	it "loads config/serve.rb as protocol middleware" do
		FileUtils.mkdir_p(File.join(root, "config"))
		File.write(File.join(root, "config/serve.rb"), "run Protocol::HTTP::Middleware::Okay\n")
		
		expect(evaluator.middleware).to be_a(Protocol::HTTP::Middleware)
	end
	
	it "falls back to config.ru" do
		File.write(File.join(root, "config.ru"), "run ->(env) {[200, {}, []]}\n")
		
		expect(evaluator.resolved_configuration_path).to be == File.join(root, "config.ru")
	end
	
	it "uses an explicit configuration path" do
		evaluator = Async::Service::Environment.build(
			Falcon::Environment::Server,
			subject,
			root: root,
			name: "localhost",
			configuration_path: "application.rb",
		).evaluator
		
		expect(evaluator.resolved_configuration_path).to be == File.join(root, "application.rb")
	end
	
	it "rejects unsupported configuration extensions" do
		evaluator = Async::Service::Environment.build(
			Falcon::Environment::Server,
			subject,
			root: root,
			name: "localhost",
			configuration_path: "application.txt",
		).evaluator
		
		expect do
			evaluator.middleware
		end.to raise_exception(ArgumentError, message: be(:include?, "Unsupported application configuration"))
	end
	
	it "fails when no configuration exists" do
		expect do
			evaluator.resolved_configuration_path
		end.to raise_exception(ArgumentError, message: be(:include?, "Could not find"))
	end
end
