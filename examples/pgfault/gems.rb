# frozen_string_literal: true

source "https://rubygems.org"

gem "falcon"

group :preload do
	gem 'rdkafka', '~> 0.21.0'
end
