# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024-2026, by Samuel Williams.

require "falcon/service/server"
require "falcon/environment/server"
require "falcon/environment/rackup"
require "sus/fixtures/async/scheduler_context"
require "async/container"
require "async/http/client"
require "async/service/environment"

AStoppingServer = Sus::Shared("a stopping server") do
	let(:arrived) {IO.pipe}
	let(:proceed) {IO.pipe}
	
	# Reports each request to `/slow`, and then holds it until the test lets it proceed.
	let(:application) do
		arrived_output = arrived.last
		proceed_input = proceed.first
		
		Module.new do
			define_method(:middleware) do
				Protocol::HTTP::Middleware.for do |request|
					if request.path == "/slow"
						arrived_output.write(".")
						proceed_input.read(1)
					end
					
					Protocol::HTTP::Response[200, {}, ["Hello World"]]
				end
			end
		end
	end
	
	let(:environment) do
		Async::Service::Environment.new(Falcon::Environment::Server).with(
			application,
			name: "hello",
			root: __dir__,
			url: "http://127.0.0.1:0",
			container_options: container_options,
		)
	end
	
	after do
		[*arrived, *proceed].each(&:close)
	end
	
	it "refuses new connections and finishes the requests in flight" do
		container = container_class.new
		
		server.start
		address = server.with_listener(environment.evaluator){|listener| listener.addresses.first}
		server.setup(container)
		container.wait_until_ready
		
		client = Async::HTTP::Client.new(Async::HTTP::Endpoint.parse("http://#{address.ip_address}:#{address.ip_port}"))
		request = Async{client.get("/slow").read}
		arrived.first.read(1)
		
		server.stop
		
		# Only Linux can shut down a listening socket:
		if RUBY_PLATFORM.include?("linux")
			expect do
				Socket.tcp(address.ip_address, address.ip_port).close
			end.to raise_exception(Errno::ECONNREFUSED)
		end
		
		proceed.last.write(".")
		expect(request.wait).to be == "Hello World"
	ensure
		client&.close
		server.stop
		container&.stop
	end
end

describe Falcon::Service::Server do
	include Sus::Fixtures::Async::SchedulerContext
	
	let(:environment) do
		Async::Service::Environment.new(Falcon::Environment::Server).with(
			Falcon::Environment::Rackup,
			name: "hello",
			root: File.expand_path(".server/hello", __dir__),
			url: "http://localhost:0",
		)
	end
	
	let(:server) do
		subject.new(environment)
	end
	
	it "can create a server" do
		expect(server).to be_a subject
	end
	
	it "binds a listener shared by its workers" do
		server.start
		
		server.with_listener(environment.evaluator) do |listener|
			expect(listener).to be_a(Falcon::Listener)
			expect(listener.endpoint).to be_a(Falcon::Listener::Endpoint)
			expect(listener).to have_attributes(
				name: be == "hello",
				scheme: be == "http",
				protocols: be(:include?, "http/1.1"),
			)
			expect(listener.addresses.first.ip?).to be == true
		end
	ensure
		server.stop
	end
	
	it "can start and stop server" do
		container = Async::Container.new
		
		server.start
		server.setup(container)
		container.wait_until_ready
		
		expect(container.group.running).to have_attributes(size: be == Etc.nprocessors)
		
		server.stop
		container.stop
	end
	
	with "a limited count" do
		let(:environment) do
			Async::Service::Environment.new(Falcon::Environment::Server).with(
				Falcon::Environment::Rackup,
				name: "hello",
				root: File.expand_path(".server/hello", __dir__),
				url: "http://localhost:0",
				count: 1,
			)
		end
		
		it "can start and stop server" do
			container = Async::Container.new
			
			server.start
			server.setup(container)
			container.wait_until_ready
			
			expect(container.group.running).to have_attributes(size: be == 1)
			
			server.stop
			container.stop
		end
	end
	
	with "legacy make_supervised_worker" do
		let(:instance) {Object.new}
		
		let(:supervised_worker) do
			worker = Object.new
			def worker.run
				# Mock method - will be stubbed by expect
			end
			worker
		end
		
		let(:mock_server) do
			server = Object.new
			def server.run
				# Mock method - will be stubbed by expect
			end
			server
		end
		
		it "invokes make_supervised_worker when evaluator responds to it" do
			server.start
			
			evaluator = environment.evaluator
			
			# Verify make_supervised_worker is called with the instance and returns supervised_worker
			expect(evaluator).to receive(:make_supervised_worker).with(instance).and_return(supervised_worker)
			
			# Verify supervised_worker.run is called
			expect(supervised_worker).to receive(:run)
			
			# Mock make_server to return our mock server
			expect(evaluator).to receive(:make_server).and_return(mock_server)
			
			# Mock server.run to avoid errors in the Async block
			expect(mock_server).to receive(:run)
			
			Async do
				result = server.run(instance, evaluator)
				expect(result).to be == mock_server
			end.wait
			
			server.stop
		end
	end
	
	it "propagates server IO errors" do
		evaluator = Object.new
		bound_endpoint = Object.new
		listener = Struct.new(:endpoint).new(bound_endpoint)
		failing_server = Object.new
		condition = Async::Condition.new
		
		failing_server.define_singleton_method(:run) do
			Async do
				condition.wait
				raise IOError, "application failure"
			end
		end
		
		evaluator.define_singleton_method(:make_server) do |endpoint|
			raise ArgumentError, "Unexpected endpoint!" unless endpoint.equal?(bound_endpoint)
			failing_server
		end
		
		expect do
			Async do |task|
				server.run(nil, evaluator, listener)
				condition.signal
				task.children.each(&:wait)
			end.wait
		end.to raise_exception(IOError, message: be == "application failure")
	end
	
	with "a forked container", if: Process.respond_to?(:fork) do
		let(:container_class) {Async::Container::Forked}
		let(:container_options) {{restart: false, count: 2}}
		
		it_behaves_like AStoppingServer
	end
	
	it "doesn't shut down the listener when its workers are threads" do
		container = Class.new(Async::Container::Threaded) do
			def run(...)
				self
			end
		end.new
		
		server.start
		address, shared = server.with_listener(environment.evaluator) do |listener|
			# These duplicates keep the sockets open, so they go on listening unless they are shut down:
			[listener.addresses.first, listener.endpoint.bind]
		end
		server.setup(container)
		
		server.stop
		
		expect do
			Socket.tcp(address.ip_address, address.ip_port).close
		end.not.to raise_exception
	ensure
		shared&.each(&:close)
	end
	
	with "a hybrid container", if: Process.respond_to?(:fork) do
		let(:container_class) {Async::Container::Hybrid}
		let(:container_options) {{restart: false, forks: 1, threads: 2}}
		
		it_behaves_like AStoppingServer
	end
end
