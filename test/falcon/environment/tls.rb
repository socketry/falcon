# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "falcon/environment/tls"
require "async/service/environment"
require "sus/fixtures/openssl/valid_certificate_context"
require "sus/fixtures/temporary_directory_context"
require "fileutils"
require "socket"

describe Falcon::Environment::TLS do
	include Sus::Fixtures::TemporaryDirectoryContext
	include Sus::Fixtures::OpenSSL::ValidCertificateContext
	
	let(:evaluator) do
		Async::Service::Environment.build(subject, root: root).evaluator
	end
	
	def write_certificate_files
		FileUtils.mkdir_p(File.join(root, "ssl"))
		
		File.write(evaluator.ssl_certificate_path, certificate.to_pem)
		File.write(evaluator.ssl_private_key_path, key.to_pem)
	end
	
	def client_context(max_version: nil)
		OpenSSL::SSL::SSLContext.new.tap do |context|
			context.verify_mode = OpenSSL::SSL::VERIFY_NONE
			
			if max_version
				context.max_version = max_version
			end
		end
	end
	
	# Perform a loopback TLS handshake between the environment's server context and the given client context, yielding both sockets once connected.
	def handshake(client_context)
		server_socket, client_socket = UNIXSocket.pair
		
		server = OpenSSL::SSL::SSLSocket.new(server_socket, evaluator.ssl_context)
		client = OpenSSL::SSL::SSLSocket.new(client_socket, client_context)
		
		server_thread = Thread.new do
			server.accept
		rescue OpenSSL::SSL::SSLError
			# The client will also see the handshake failure.
		end
		
		client.connect
		server_thread.join
		
		yield server, client
	ensure
		server_thread&.join
		server&.close
		client&.close
		server_socket&.close
		client_socket&.close
	end
	
	it "provides default TLS paths and settings" do
		expect(evaluator).to have_attributes(
			ssl_session_id: be == "falcon",
			ssl_ciphers: be == Falcon::TLS::SERVER_CIPHERS,
			ssl_certificate_path: be == File.join(root, "ssl/certificate.pem"),
			ssl_private_key_path: be == File.join(root, "ssl/private.key"),
		)
	end
	
	it "loads certificate material from the configured paths" do
		write_certificate_files
		
		expect(evaluator.ssl_certificate.subject.to_s).to be == certificate.subject.to_s
		expect(evaluator.ssl_certificate_chain).to be(:empty?)
		expect(evaluator.ssl_private_key.to_pem).to be == key.to_pem
	end
	
	it "builds an SSL context" do
		write_certificate_files
		
		context = evaluator.ssl_context
		
		expect(context).to be_a(OpenSSL::SSL::SSLContext)
		expect(context.session_id_context).to be == "falcon"
	end
	
	it "selects an application protocol" do
		write_certificate_files
		
		callback = evaluator.ssl_context.alpn_select_cb
		
		expect(callback.call(["h2", "http/1.1"])).to be == "h2"
		expect(callback.call(["http/1.1"])).to be == "http/1.1"
		expect(callback.call(["http/1.0"])).to be == "http/1.0"
		expect(callback.call(["spdy/3"])).to be == nil
	end
	
	with "protocol version negotiation" do
		before do
			write_certificate_files
		end
		
		it "negotiates TLS 1.3 with a modern client" do
			handshake(client_context) do |server, client|
				expect(server.ssl_version).to be == "TLSv1.3"
				expect(client.ssl_version).to be == "TLSv1.3"
			end
		end
		
		it "still accepts TLS 1.2 clients" do
			handshake(client_context(max_version: OpenSSL::SSL::TLS1_2_VERSION)) do |server, client|
				expect(server.ssl_version).to be == "TLSv1.2"
				expect(client.ssl_version).to be == "TLSv1.2"
			end
		end
		
		# This is a behavioural guard that the server refuses legacy clients. It does not prove that `min_version` is the mechanism: OpenSSL 3+ at the default security level also refuses TLS 1.1, and `SSLContext` has no `min_version` reader to inspect.
		it "rejects clients older than TLS 1.2" do
			# Modern OpenSSL refuses TLS 1.1 at the default security level, so lower it on the client to ensure the server is what rejects the handshake:
			legacy_client_context = client_context(max_version: OpenSSL::SSL::TLS1_1_VERSION)
			legacy_client_context.security_level = 0
			
			# A system `openssl.cnf` may set `MinProtocol = TLSv1.2`, in which case the client would fail locally with "no protocols available" before sending anything, so pin the client's floor explicitly:
			legacy_client_context.min_version = OpenSSL::SSL::TLS1_1_VERSION
			
			expect do
				handshake(legacy_client_context) {}
			end.to raise_exception(OpenSSL::SSL::SSLError, message: be =~ /protocol version/)
		end
	end
end
