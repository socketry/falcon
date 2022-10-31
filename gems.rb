# frozen_string_literal: true

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

group :maintenance, optional: true do
	gem "bake-modernize"
	gem "bake-gem"

	gem "bake-github-pages"
	gem "utopia-project"
end

group :development do
	gem 'ruby-prof', platform: :mri
end

group :test do
	gem 'puma'
	gem 'bake-test'
	gem 'bake-test-external'
	
	gem "rackup"
end
