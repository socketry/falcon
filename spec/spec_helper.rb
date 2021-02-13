# frozen_string_literal: true

require "covered/rspec"

require "async"
require "async/rspec"

ENV['PATH'] = [File.expand_path('../bin', __dir__), ENV['PATH']].join(':')

require 'openssl'
$stderr.puts "OpenSSL::OPENSSL_LIBRARY_VERSION: #{OpenSSL::OPENSSL_LIBRARY_VERSION}"

RSpec.configure do |config|
	# Enable flags like --only-failures and --next-failure
	config.example_status_persistence_file_path = ".rspec_status"

	# Disable RSpec exposing methods globally on `Module` and `main`
	config.disable_monkey_patching!

	config.expect_with :rspec do |c|
		c.syntax = :expect
	end
end
