# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2020, by Samuel Williams.
# Copyright, 2020, by Daniel Evans.

require 'falcon/configuration'

RSpec.describe Falcon::Configuration do
	it "can configurure proxy" do
		subject.load_file(File.expand_path("configuration_spec/proxy.rb", __dir__))
		
		expect(subject.environments).to include('localhost')
	end
	
	it "can configure rack" do
		subject.load_file(File.expand_path("configuration_spec/rack.rb", __dir__))
		
		expect(subject.environments).to include('localhost')
	end
end
