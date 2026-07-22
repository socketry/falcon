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
	
	def make_binding(*addresses)
		sockets = addresses.map do |address|
			io = Struct.new(:local_address).new(address)
			Struct.new(:to_io).new(io)
		end
		
		endpoint = Struct.new(:sockets).new(sockets)
		subject::Binding.new(endpoint: endpoint)
	end
	
	it "captures all addresses from the bound endpoint" do
		ip_address = Addrinfo.tcp("127.0.0.1", 9292)
		unix_address = Addrinfo.unix("/tmp/falcon.sock")
		binding = make_binding(ip_address, unix_address)
		
		expect(binding).to have_attributes(
			addresses: be == [ip_address, unix_address],
			address: be == "127.0.0.1",
			port: be == 9292,
			path: be == "/tmp/falcon.sock",
			frozen?: be == true,
		)
		expect(binding.addresses.frozen?).to be == true
	end
	
	it "exposes an IP address and port without a Unix socket path" do
		binding = make_binding(Addrinfo.tcp("127.0.0.1", 9292))
		
		expect(binding.address).to be == "127.0.0.1"
		expect(binding.port).to be == 9292
		expect(binding.path).to be == nil
	end
	
	it "exposes a Unix socket path without an IP address and port" do
		binding = make_binding(Addrinfo.unix("/tmp/falcon.sock"))
		
		expect(binding.address).to be == nil
		expect(binding.port).to be == nil
		expect(binding.path).to be == "/tmp/falcon.sock"
	end
	
	let(:recorder) do
		path = ports_path
		
		Module.new do
			def middleware
				Protocol::HTTP::Middleware::HelloWorld
			end
			
			def container_options
				super.merge(restart: false)
			end
			
			define_method(:prepare_worker!) do |instance, binding|
				super(instance, binding)
				
				File.open(path, "a") do |file|
					file.puts(binding.port)
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
