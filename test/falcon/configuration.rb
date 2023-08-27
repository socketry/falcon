# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2020, by Samuel Williams.
# Copyright, 2020, by Daniel Evans.

require 'falcon/configuration'

describe Falcon::Configuration do
	let(:configuration) {subject.new}
	
	it "can configurure proxy" do
		configuration.load_file(File.expand_path(".configuration/proxy.rb", __dir__))
		
		expect(configuration.environments).to be(:include?, 'localhost')
	end
	
	it "can configure rack" do
		configuration.load_file(File.expand_path(".configuration/rack.rb", __dir__))
		
		expect(configuration.environments).to be(:include?, 'localhost')
	end
end
