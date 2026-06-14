# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "falcon/proxy_endpoint"

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
end
