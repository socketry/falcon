# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2022, by Samuel Williams.
# Copyright, 2018, by Mitsutaka Mimura.
# Copyright, 2019, by Bryan Powell.

require_relative 'shared_examples'
require 'rack/handler/falcon'

RSpec.describe Rackup::Handler::Falcon do
	it_behaves_like Rackup::Handler, 'falcon'

	let(:app) {lambda {|env| [200, {}, ["Hello World"]]}}

	it "can start and stop server" do
		Rackup::Handler::Falcon.run(app) do |server|
			server.stop
		end
	end
end
