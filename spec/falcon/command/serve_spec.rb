# Copyright, 2018, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

require 'falcon/command/serve'

RSpec.shared_examples_for Falcon::Command::Serve do
	let(:command) do
		described_class[
			"--port", 8090,
			"--config", File.expand_path("config.ru", __dir__), *options
		]
	end
	
	it "can listen on specified port" do
		container = command.run(true)
		
		begin
			Async do
				client = command.client
				
				response = client.get("/")
				expect(response).to be_success
				
				response.finish
				client.close
			end
		ensure
			container.stop(false)
		end
	end
end

RSpec.describe Falcon::Command::Serve do
	let(:options) { [] }

	context "with custom port" do
		include_examples Falcon::Command::Serve
	end
	
	context "with one instance" do
		let(:options) {["--count", 1]}
		include_examples Falcon::Command::Serve
	end
	
	context "with threaded container" do
		let(:options) {["--count", 8, "--threaded"]}
		include_examples Falcon::Command::Serve
	end
	
	context "with forked container", if: Process.respond_to?(:fork) do
		let(:options) {["--count", 8, "--forked"]}
		include_examples Falcon::Command::Serve
	end
end
