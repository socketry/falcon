# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "falcon/listener"
require "io/endpoint/host_endpoint"
require "sus/fixtures/async/scheduler_context"

describe Falcon::Listener::Endpoint do
	include Sus::Fixtures::Async::SchedulerContext
	
	let(:endpoint) {subject.bound(IO::Endpoint.tcp("127.0.0.1", 0))}
	let(:listener) {Falcon::Listener.new(name: "hello", scheme: "http", protocols: ["http/1.1"], endpoint: endpoint)}
	let(:address) {listener.addresses.first}
	
	after do
		endpoint.close
	end
	
	it "duplicates the bound sockets" do
		sockets = endpoint.bind
		
		expect(sockets.size).to be == 1
		expect(sockets.first.local_address.ip_port).to be == address.ip_port
		expect(sockets.first.fileno).not.to be == endpoint.sockets.first.fileno
	ensure
		sockets&.each(&:close)
	end
	
	it "accepts connections" do
		accepted = Async::Queue.new
		
		accepting = Async do |task|
			endpoint.accept do |peer|
				accepted.enqueue(peer.read)
			end
			
			task.children.each(&:wait)
		end
		
		Socket.tcp(address.ip_address, address.ip_port) do |socket|
			socket.write("Hello World")
		end
		
		expect(accepted.dequeue).to be == "Hello World"
	ensure
		accepting&.stop
	end
	
	it "waits to be stopped once the listener has shut down" do
		skip "Only Linux can shut down a listening socket!" unless RUBY_PLATFORM.include?("linux")
		
		accepting = Async do |task|
			endpoint.bind do |server|
				listener.shutdown
				server.accept
			end
			
			task.children.each(&:wait)
		end
		
		expect(accepting).to be(:running?)
	ensure
		accepting&.stop
	end
	
	it "raises an error from a socket that is still listening" do
		accepting = Async do |task|
			endpoint.bind do
				# Fail once the parent task is waiting, so that the failure is reported to it:
				sleep(0.001)
				raise Errno::EINVAL
			end
			
			task.children.each(&:wait)
		end
		
		expect{accepting.wait}.to raise_exception(Errno::EINVAL)
	end
end
