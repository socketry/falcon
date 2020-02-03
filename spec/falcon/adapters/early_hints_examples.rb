# frozen_string_literal: true

# Copyright, 2019, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require_relative '../server_context'

RSpec.shared_examples_for Falcon::Adapters::EarlyHints do
	include_context Falcon::Server
	
	let(:protocol) {Async::HTTP::Protocol::HTTP2::WithPush}
	
	let(:text) {"Hello World!"}
	let(:css) {"all {your: base are belong to us;}"}
	let(:links) {[["link", "</index.css>; rel=preload"]]}
	
	let(:app) do
		lambda do |env|
			request = Rack::Request.new(env)
			
			if request.path == "/index.css"
				[200, {}, [css]]
			else
				if early_hints = env['rack.early_hints']
					early_hints.call(links)
				end
				
				[200, {}, [text]]
			end
		end
	end
	
	let(:response) {client.get("/")}
	
	it "generates successful response and promise" do
		expect(response).to be_success
		expect(response.read).to be == text
		
		promise = response.promises.dequeue
		promise.wait
		
		expect(promise).to be_success
		expect(promise.read).to be == css
	end
end
