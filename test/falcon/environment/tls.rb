# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "falcon/environment/tls"
require "async/service/environment"
require "sus/fixtures/openssl/valid_certificate_context"
require "sus/fixtures/temporary_directory_context"
require "fileutils"

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
end
