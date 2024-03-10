# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2023, by Samuel Williams.

source 'https://rubygems.org'

gemspec

# gem "async-container", path: "../async-container"
# gem "async-websocket", path: "../async-websocket"
# gem "async-http", path: "../async-http"
# gem "async-http-cache", path: "../async-http-cache"
# gem "protocol-http", path: "../protocol-http"
# gem "protocol-http1", path: "../protocol-http1"
# gem "utopia-project", path: "../utopia-project"
# gem "protocol-rack", path: "../protocol-rack"
# gem "async-service", path: "../async-service"

group :maintenance, optional: true do
	gem "bake-modernize"
	gem "bake-gem"

	gem "utopia-project"
end

group :development do
	gem 'ruby-prof', platform: :mri
end

group :test do
	gem 'sus'
	gem 'covered'
	
	gem 'sus-fixtures-async'
	gem 'sus-fixtures-async-http'
	gem 'sus-fixtures-openssl'
	
	gem "bake"
	gem 'bake-test'
	gem 'bake-test-external'
	
	gem 'puma'
	gem "rackup"
	
	gem "async-process", "~> 1.1"
	gem "async-websocket", "~> 0.19.2"
end
