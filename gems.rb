# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2024, by Samuel Williams.

source "https://rubygems.org"

gemspec

# gem "async-http", path: "../async-http"
# gem "async-http", path: "../async-http-native-io"
# gem "openssl", git: "https://github.com/ruby/openssl.git"
# gem "async-container", path: "../async-container"
# gem "async-container-supervisor", path: "../async-container-supervisor"
# gem "async-websocket", path: "../async-websocket"
# gem "async-http", path: "../async-http"
# gem "async-http-cache", path: "../async-http-cache"
# gem "protocol-http", path: "../protocol-http"
# gem "protocol-http1", path: "../protocol-http1"
# gem "protocol-http2", path: "../protocol-http2"
# gem "utopia-project", path: "../utopia-project"
# gem "protocol-rack", path: "../protocol-rack"
# gem "async-service", path: "../async-service"
# gem "io-stream", path: "../io-stream"
# gem "memory-leak", path: "../memory-leak"

# gem "fiber-profiler"

group :maintenance, optional: true do
	gem "bake-modernize"
	gem "bake-gem"

	gem "utopia-project"
	gem "bake-releases"
end

group :development do
	gem "ruby-prof", platform: :mri
	gem "io-watch"
end

group :test do
	gem "sus"
	gem "covered"
	gem "decode"
	gem "rubocop"
	
	gem "sus-fixtures-async"
	gem "sus-fixtures-async-http"
	gem "sus-fixtures-openssl"
	
	gem "bake"
	gem "bake-test"
	gem "bake-test-external"
	
	gem "puma"
	gem "rackup"
	
	gem "async-process"
	gem "async-websocket"
end
