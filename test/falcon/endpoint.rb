# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "falcon/endpoint"

describe Falcon::Endpoint do
	let(:endpoint) do
		subject.parse("https://localhost:9292")
	end
	
	it "selects an application protocol" do
		callback = endpoint.build_ssl_context.alpn_select_cb
		
		expect(callback.call(["h2", "http/1.1"])).to be == "h2"
		expect(callback.call(["http/1.1"])).to be == "http/1.1"
		expect(callback.call(["http/1.0"])).to be == "http/1.0"
		expect(callback.call(["spdy/3"])).to be == nil
	end
end
