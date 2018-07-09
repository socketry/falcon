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

require 'falcon/adapters/input'

RSpec.describe Falcon::Adapters::Input do
	include_context Async::RSpec::Memory

	context 'with body' do
		let(:sample_data) {%w{The quick brown fox jumped over the lazy dog}}
		let(:body) {Async::HTTP::Body::Buffered.new(sample_data)}
		
		subject {described_class.new(body)}
		
		context '#read(length, buffer)' do
			let(:buffer) {Async::IO::Buffer.new}
			let(:expected_output) {sample_data.join}
			
			it "can read partial input" do
				expect(subject.read(3, buffer)).to be == "The"
				expect(buffer).to be == "The"
			end
			
			it "can read all input" do
				expect(subject.read(expected_output.bytesize, buffer)).to be == expected_output
				expect(buffer).to be == expected_output
				
				# Not sure about this. The next read will not produce any additional data, but we don't konw if we are at EOF yet.
				expect(subject).to_not be_eof
				
				expect(subject.read(expected_output.bytesize, buffer)).to be == nil
				expect(buffer).to be == ""
				
				expect(subject).to be_eof
			end
			
			context "with large body" do
				# Allocate 5 chunks, each containing 1 MB of data.
				let(:sample_data) {Array.new(5) {|i| "#{i}" * 1024*1024}}
				
				it "allocates expected amount of memory" do
					subject
					
					expect do
						subject.read(10*1024, buffer)
					end.to limit_allocations.of(String, count: 1)
				end
			end
		end
		
		context '#read' do
			it "can read all input" do
				expect(subject.read).to be == sample_data.join
				expect(subject.read).to be == ""
			end
			
			it "can read no input" do
				expect(subject.read(0)).to be == ""
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
				
				expect(subject.read(1)).to be == nil
				expect(subject).to be_eof
			end
			
			it "can read partial input with buffer" do
				buffer = String.new
				
				2.times do
					expect(subject.read(3, buffer)).to be == "The"
					expect(subject.read(3, buffer)).to be == "qui"
					expect(subject.read(3, buffer)).to be == "ckb"
					expect(subject.read(3, buffer)).to be == "row"
					
					expect(buffer).to be == "row"
					
					subject.rewind
				end
				
				data = subject.read(15, buffer)
				expect(data).to be == sample_data.join[0...15]
				expect(buffer).to equal(data)
				
				expect(subject.read).to be == sample_data.join[15..-1]
				
				expect(subject.read(1, buffer)).to be == nil
				expect(buffer).to be == ""
				
				expect(subject).to be_eof
			end
			
			context "with large body" do
				let(:sample_data) { Array.new(5) { |i| "#{i}" * 1024*1024 } }
				
				it "allocates expected amount of memory" do
					expect {
						subject.read.clear
					}.to limit_allocations(size: 6*1024*1024)
				end
			end
		end
		
		context '#gets' do
			it "can read chunks" do
				sample_data.each do |chunk|
					expect(subject.gets).to be == chunk
				end
				
				expect(subject.gets).to be == nil
			end
			
			it "returns remainder after calling #read" do
				expect(subject.read(4)).to be == "Theq"
				expect(subject.gets).to be == "uick"
				expect(subject.read(4)).to be == "brow"
				expect(subject.gets).to be == "n"
			end
		end
		
		context '#each' do
			it "can read chunks" do
				subject.each.with_index do |chunk, index|
					expect(chunk).to be == sample_data[index]
				end
			end
		end
		
		context '#eof?' do
			it "should not be at end of file" do
				expect(subject).to_not be_eof
			end
		end
		
		context '#rewind' do
			it "reads same chunk again" do
				expect(subject.gets).to be == "The"
				
				subject.rewind
				expect(subject.gets).to be == "The"
			end
			
			it "clears unread buffer" do
				expect(subject.gets).to be == "The"
				expect(subject.read(2)).to be == "qu"
				
				subject.rewind
				
				expect(subject.read(3)).to be == "The"
			end
		end
	end
	
	context 'without body' do
		subject {described_class.new(nil)}
		
		context '#read(length, buffer)' do
			let(:buffer) {Async::IO::Buffer.new}
			
			it "can read no input" do
				expect(subject.read(0, buffer)).to be == ""
				expect(buffer).to be == ""
			end
			
			it "can read partial input" do
				expect(subject.read(2, buffer)).to be == nil
				expect(buffer).to be == ""
			end
		end
		
		context '#read' do
			it "can read all input" do
				expect(subject.read).to be == ""
			end
			
			it "can read no input" do
				expect(subject.read(0)).to be == ""
			end
			
			it "can read partial input" do
				expect(subject.read(2)).to be_nil
			end
		end
		
		context '#gets' do
			it "can read chunks" do
				expect(subject.gets).to be_nil
			end
		end
		
		context '#eof?' do
			it "should be at end of file" do
				expect(subject).to be_eof
			end
		end
	end
end