# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "falcon/listener"
require "io/endpoint/host_endpoint"
require "io/endpoint/unix_endpoint"
require "tmpdir"

describe Falcon::Listener do
	def make_listener(*addresses, name: "hello", scheme: "http", protocols: ["http/1.1", "http/1.0"])
		sockets = addresses.map do |address|
			io = Struct.new(:local_address).new(address)
			Struct.new(:to_io).new(io)
		end
		
		endpoint = Struct.new(:sockets) do
			attr_reader :closed
			
			def close
				@closed = true
			end
		end.new(sockets)
		subject.new(name: name, scheme: scheme, protocols: protocols, endpoint: endpoint)
	end
	
	it "describes a bound listener" do
		ip_address = Addrinfo.tcp("127.0.0.1", 9292)
		unix_address = Addrinfo.unix("/tmp/falcon.sock")
		listener = make_listener(ip_address, unix_address)
		
		expect(listener).to have_attributes(
			name: be == "hello",
			scheme: be == "http",
			protocols: be == ["http/1.1", "http/1.0"],
			addresses: be == [ip_address, unix_address],
			frozen?: be == true,
		)
		expect(listener.addresses.frozen?).to be == true
		expect(listener.protocols.frozen?).to be == true
	end
	
	it "closes the bound endpoint" do
		listener = make_listener(Addrinfo.tcp("127.0.0.1", 9292))
		
		listener.close
		
		expect(listener.endpoint.closed).to be == true
	end
	
	it "stops listening on a socket that another descriptor keeps open" do
		skip "Only Linux can shut down a listening socket!" unless RUBY_PLATFORM.include?("linux")
		
		endpoint = subject::Endpoint.bound(IO::Endpoint.tcp("127.0.0.1", 0))
		listener = subject.new(name: "hello", scheme: "http", protocols: ["http/1.1"], endpoint: endpoint)
		address = listener.addresses.first
		
		# A forked worker holds its own descriptor for the socket, as these duplicates do:
		inherited = endpoint.bind
		
		listener.shutdown
		listener.close
		
		expect do
			Socket.tcp(address.ip_address, address.ip_port).close
		end.to raise_exception(Errno::ECONNREFUSED)
	ensure
		inherited&.each(&:close)
		endpoint&.close
	end
	
	it "leaves a UNIX socket listening" do
		Dir.mktmpdir do |directory|
			path = File.join(directory, "falcon.ipc")
			endpoint = subject::Endpoint.bound(IO::Endpoint.unix(path))
			listener = subject.new(name: "hello", scheme: "http", protocols: ["http/1.1"], endpoint: endpoint)
			
			listener.shutdown
			
			expect do
				UNIXSocket.new(path).close
			end.not.to raise_exception
		ensure
			endpoint&.close
		end
	end
end
