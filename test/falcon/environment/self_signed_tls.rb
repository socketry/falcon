# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "falcon/environment/self_signed_tls"
require "async/service/environment"

describe Falcon::Environment::SelfSignedTLS do
	let(:evaluator) do
		Async::Service::Environment.build(subject, authority: "localhost").evaluator
	end
	
	it "returns nil for unsupported application protocols" do
		callback = evaluator.ssl_context.alpn_select_cb
		
		expect(callback.call(["spdy/3"])).to be == nil
	end
end
