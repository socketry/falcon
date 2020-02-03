# frozen_string_literal: true

# Copyright, 2017, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

require_relative 'shared_examples'
require 'rack/handler/falcon'

RSpec.describe Rack::Handler::Falcon do
	it_behaves_like Rack::Handler, 'falcon'
	
	let(:server_double) {instance_double(Falcon::Server)}

	before do
		allow(Async::Reactor).to receive(:run)
		allow(Falcon::Server).to receive(:new).and_return(server_double)
	end

	context 'block is given' do
		it 'yields server' do
			expect do |block|
				described_class.run(double(call: true), &block)
			end.to yield_with_args(server_double)
		end
	end

	context 'block is not given' do
		it 'does not fail' do
			expect do |block|
				described_class.run(double(call: true), &block)
			end.not_to raise_error
		end
	end
end
