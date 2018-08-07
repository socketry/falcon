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

require 'falcon/server'
require 'async/websocket/server'
require 'async/websocket/client'

RSpec.describe Falcon::Adapters::Response do
	context 'with #to_path' do
		let(:body) {double}
		
		it "should generate file body" do
			expect(body).to receive(:to_path).and_return("/dev/null")
			
			response = described_class.new(200, {}, body)
			
			expect(response.body).to be_kind_of Async::HTTP::Body::File
		end
		
		it "should not modify partial responses" do
			response = described_class.new(206, {}, body)
			
			expect(response.body).to be_kind_of Falcon::Adapters::Output
		end
	end
	
	context 'with content-length' do
		it "should remove header" do
			response = described_class.new(200, {'Content-Length' => '4'}, ["1234"])
			
			expect(response.headers).to_not include('content-length')
		end
	end
end
