# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "falcon/body/request_finished"
require "protocol/http/body/buffered"
require "protocol/http/response"
require "async/utilization"
require "sus/fixtures/async"

describe Falcon::Body::RequestFinished do
	include Sus::Fixtures::Async::ReactorContext
	
	let(:registry) {Async::Utilization::Registry.new}
	let(:metric) {registry.metric(:requests_active)}
	let(:body) {Protocol::HTTP::Body::Buffered.wrap("Hello World")}
	let(:response) {Protocol::HTTP::Response[200, {"content-type" => "text/plain"}, body]}
	
	with ".wrap" do
		with "non-empty body" do
			it "wraps body and decrements metric when body is closed" do
				metric.increment
				expect(metric.value).to be == 1
				
				wrapped = subject.wrap(response, metric)
				expect(wrapped).to be == response
				expect(response.body).to be_a(subject)
				expect(metric.value).to be == 1
				
				response.body.close
				expect(metric.value).to be == 0
			end
			
			it "decrements only once on multiple close calls" do
				metric.increment
				subject.wrap(response, metric)
				
				response.body.close
				response.body.close
				
				expect(metric.value).to be == 0
			end
		end
		
		with "empty body" do
			let(:body) {Protocol::HTTP::Body::Buffered.new}
			
			it "decrements immediately" do
				metric.increment
				expect(metric.value).to be == 1
				
				subject.wrap(response, metric)
				expect(metric.value).to be == 0
				expect(response.body).to be_equal(body)
			end
		end
		
		with "nil body" do
			let(:response) {Protocol::HTTP::Response[204, {}, nil]}
			
			it "decrements immediately" do
				metric.increment
				expect(metric.value).to be == 1
				
				subject.wrap(response, metric)
				expect(metric.value).to be == 0
			end
		end
		
		with "nil message" do
			it "decrements immediately" do
				metric.increment
				subject.wrap(nil, metric)
				expect(metric.value).to be == 0
			end
		end
	end
	
	with "#rewindable?" do
		it "returns false" do
			subject.wrap(response, metric)
			expect(response.body).not.to be(:rewindable?)
		end
	end
	
	with "#rewind" do
		it "returns false" do
			subject.wrap(response, metric)
			expect(response.body.rewind).to be == false
		end
	end
end
