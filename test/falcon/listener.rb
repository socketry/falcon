# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "falcon/listener"

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
end
