# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

# gem "async-container", path: "../async-container"
# gem "async-websocket", path: "../async-websocket"
# gem "async-http", path: "../async-http"
# gem "protocol-http1", path: "../protocol-http1"
# gem "utopia-project", path: "../utopia-project"
# gem "decode", path: "../../ioquatix/decode"

group :development do
	gem 'ruby-prof', platform: :mri
end

group :test do
	gem 'puma'
end
