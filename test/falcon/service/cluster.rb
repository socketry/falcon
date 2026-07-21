# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "falcon/service/cluster"
require "falcon/environment/cluster"
require "async/container"
require "async/service/environment"
require "fileutils"
require "net/http"
require "protocol/http/middleware"

describe Falcon::Service::Cluster do
	let(:ports_path) {File.expand_path(".cluster/ports.txt", __dir__)}
	
	let(:recorder) do
		path = ports_path
		
		Module.new do
			def middleware
				Protocol::HTTP::Middleware::HelloWorld
			end
			
			def container_options
				super.merge(restart: false)
			end
			
			define_method(:prepare!) do |instance|
				super(instance)
				
				File.open(path, "a") do |file|
					file.puts(bound_port)
				end
			end
		end
	end
	
	let(:environment) do
		Async::Service::Environment.new(Falcon::Environment::Cluster).with(
			recorder,
			name: "hello",
			root: File.expand_path(".cluster/hello", __dir__),
			url: "http://127.0.0.1:0",
			count: 2,
			health_check_timeout: 0.01,
		)
	end
	
	let(:server) do
		subject.new(environment)
	end
	
	before do
		FileUtils.rm_rf(File.dirname(ports_path))
		FileUtils.mkdir_p(File.dirname(ports_path))
	end
	
	after do
		FileUtils.rm_rf(File.dirname(ports_path))
	end
	
	it "binds a unique port for each worker before preparing the instance" do
		container = Async::Container.new
		
		server.start
		server.setup(container)
		container.wait_until_ready
		
		ports = File.readlines(ports_path, chomp: true).map(&:to_i)
		
		expect(ports).to have_attributes(size: be == 2)
		expect(ports).to have_value(be > 0)
		expect(ports.uniq).to be == ports
		
		ports.each do |port|
			response = Net::HTTP.get_response(URI("http://127.0.0.1:#{port}/"))
			
			expect(response).to have_attributes(code: be == "200")
		end
		
		sleep(0.01)
		
		container.stop
		expect(container.failed?).to be_falsey
	ensure
		server.stop
		container&.stop unless container&.stopping?
	end
end
