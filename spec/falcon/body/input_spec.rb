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

require 'falcon/body/input'

RSpec.describe Falcon::Body::Input do
	let(:sample_data) {%w{The quick brown fox jumped over the lazy dog}}
	let(:body) {Async::HTTP::Body::Buffered.new(sample_data)}
	
	subject {described_class.new(body)}
	
	context '#read' do
		it "can read all input" do
			expect(subject.read).to be == sample_data.join
		end
		
		it "can read partial input" do
			2.times do
				expect(subject.read(3)).to be == "The"
				expect(subject.read(3)).to be == "qui"
				expect(subject.read(3)).to be == "ckb"
				expect(subject.read(3)).to be == "row"
				
				subject.rewind
			end
			
			expect(subject.read(15)).to be == sample_data.join[0...15]
			expect(subject.read).to be == sample_data.join[15..-1]
			
			expect(subject).to be_eof
		end
	end
	
	context '#each' do
		it "can read chunks" do
			subject.each.with_index do |chunk, index|
				expect(chunk).to be == sample_data[index]
			end
		end
	end
end
