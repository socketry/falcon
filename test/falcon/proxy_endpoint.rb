# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "falcon/proxy_endpoint"

require "async/http/protocol"
require "io/endpoint/host_endpoint"
require "async/variable"
require "sus/fixtures/async/reactor_context"
require "sus/fixtures/temporary_directory_context"

describe Falcon::ProxyEndpoint do
	let(:endpoint) do
		IO::Endpoint.unix("test.ipc")
	end
	
	let(:proxy_endpoint) do
		subject.new(endpoint, protocol: Async::HTTP::Protocol::HTTP2, scheme: "https", authority: "localhost")
	end
	
	it "can enumerate proxied endpoints" do
		expect(proxy_endpoint.each).to be_a(Enumerator)
		
		proxied = proxy_endpoint.each.to_a
		
		expect(proxied).to have_attributes(size: be == 1)
		expect(proxied.first).to be_a(subject)
		expect(proxied.first).to have_attributes(
			protocol: be == Async::HTTP::Protocol::HTTP2,
			scheme: be == "https",
			authority: be == "localhost",
		)
	end
	
	it "has a default mode" do
		expect(proxy_endpoint.mode).to be == 0o600
	end
	
	it "propagates the mode to proxied endpoints" do
		proxy_endpoint = subject.new(endpoint, mode: 0o660)
		
		expect(proxy_endpoint.each.first.mode).to be == 0o660
	end
	
	with "#bind" do
		include Sus::Fixtures::Async::ReactorContext
		include Sus::Fixtures::TemporaryDirectoryContext
		
		let(:path) {File.join(root, "application.ipc")}
		let(:options) {{}}
		let(:proxy_endpoint) {subject.unix(path, **options)}
		
		def permissions(path)
			File.stat(path).mode & 0o777
		end
		
		it "restricts the socket permissions when bound" do
			bound_endpoint = proxy_endpoint.bound
			
			begin
				expect(bound_endpoint.sockets).to have_attributes(size: be == 1)
				expect(File.socket?(path)).to be == true
				expect(permissions(path)).to be == 0o600
			ensure
				bound_endpoint.close
			end
		end
		
		it "restricts the socket permissions before yielding" do
			observed = Async::Variable.new
			
			proxy_endpoint.bind do |socket|
				observed.value = permissions(path)
			end
			
			expect(observed.wait).to be == 0o600
		end
		
		def with_umask(umask)
			previous_umask = File.umask(umask)
			yield
		ensure
			File.umask(previous_umask)
		end
		
		it "creates the socket with the restricted mode even if chmod is skipped" do
			mock(proxy_endpoint) do |mock|
				mock.replace(:restrict_permissions!){|socket|}
			end
			
			with_umask(0o000) do
				bound_endpoint = proxy_endpoint.bound
				
				begin
					expect(permissions(path)).to be == 0o600
				ensure
					bound_endpoint.close
				end
			end
		end
		
		it "restores the umask after binding" do
			with_umask(0o022) do
				bound_endpoint = proxy_endpoint.bound
				
				begin
					expect(File.umask).to be == 0o022
				ensure
					bound_endpoint.close
				end
			end
		end
		
		it "restores the umask after binding with a block" do
			with_umask(0o022) do
				proxy_endpoint.bind{|socket|}
				
				expect(File.umask).to be == 0o022
			end
		end
		
		it "restores the umask if binding fails" do
			proxy_endpoint = subject.unix(File.join(root, "missing", "application.ipc"))
			
			with_umask(0o022) do
				expect{proxy_endpoint.bound}.to raise_exception(Errno::ENOENT)
				expect(File.umask).to be == 0o022
			end
		end
		
		it "accepts the wrapper argument" do
			sockets = proxy_endpoint.bind(IO::Endpoint::Wrapper.default)
			
			begin
				expect(sockets).to have_attributes(size: be == 1)
				expect(permissions(path)).to be == 0o600
			ensure
				sockets.each(&:close)
			end
		end
		
		it "can accept connections" do
			proxy_endpoint.accept do |peer|
				peer.write("hello")
				peer.close
			end
			
			proxy_endpoint.connect do |socket|
				expect(socket.read).to be == "hello"
			end
		end
		
		with "a custom mode", options: {mode: 0o660} do
			it "applies the custom mode" do
				bound_endpoint = proxy_endpoint.bound
				
				begin
					expect(permissions(path)).to be == 0o660
				ensure
					bound_endpoint.close
				end
			end
		end
		
		with "no mode", options: {mode: nil} do
			it "leaves the permissions determined by the umask" do
				with_umask(0o022) do
					bound_endpoint = proxy_endpoint.bound
					
					begin
						expect(permissions(path)).to be == 0o755
					ensure
						bound_endpoint.close
					end
				end
			end
		end
		
		with "a non-unix endpoint" do
			let(:proxy_endpoint) {subject.new(IO::Endpoint.tcp("localhost", 0))}
			
			it "binds without restricting permissions" do
				bound_endpoint = proxy_endpoint.bound
				
				begin
					expect(bound_endpoint.sockets).not.to be(:empty?)
					
					bound_endpoint.sockets.each do |socket|
						expect(socket.local_address).to be(:ip?)
					end
				ensure
					bound_endpoint.close
				end
			end
		end
	end
end
