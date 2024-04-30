# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2023, by Samuel Williams.
# Copyright, 2020, by Tasos Latsas.

require 'server_context'
require 'sus/fixtures/openssl/valid_certificate_context'
require 'sus/fixtures/openssl/verified_certificate_context'

describe Falcon::Server do
	with OpenSSL do
		include ServerContext
		include Sus::Fixtures::OpenSSL::ValidCertificateContext
		include Sus::Fixtures::OpenSSL::VerifiedCertificateContext
		
		let(:protocol) {Async::HTTP::Protocol::HTTPS}
		
		def make_server_endpoint(bound_endpoint)
			::IO::Endpoint::SSLEndpoint.new(super, ssl_context: server_context)
		end
		
		def make_client_endpoint(bound_endpoint)
			::IO::Endpoint::SSLEndpoint.new(super, ssl_context: client_context)
		end
		
		with "basic middleware" do
			let(:app) do
				lambda do |env|
					[200, {}, ["Hello World"]]
				end
			end
			
			it "client can get resource" do
				response = client.get("/", {})
				
				expect(response).to be(:success?)
				expect(response.read).to be == "Hello World"
			end
		end
	end
end
