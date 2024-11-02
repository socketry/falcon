# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2024, by Samuel Williams.
# Copyright, 2020, by Daniel Evans.

require "falcon/configuration"

describe Falcon::Configuration do
	let(:configuration) {subject.new}
	
	it "can configurure proxy" do
		configuration.load_file(File.expand_path(".configuration/proxy.rb", __dir__))
		
		expect(configuration.environments).to be(:any?)
		
		environment = configuration.environments.first
		evaluator = environment.evaluator
		
		expect(evaluator).to have_attributes(
			service_class: be == Falcon::Service::Server,
			authority: be == "localhost",
			url: be == "https://www.google.com"
		)
	end
	
	it "can configure rack" do
		configuration.load_file(File.expand_path(".configuration/rack.rb", __dir__))
		
		expect(configuration.environments).to be(:any?)
		
		environment = configuration.environments.first
		evaluator = environment.evaluator
		
		expect(evaluator).to have_attributes(
			service_class: be == Falcon::Service::Server,
			authority: be == "localhost",
			count: be == 3
		)
	end
end
