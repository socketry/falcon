source 'https://rubygems.org'

gemspec

group :development do
	gem 'ruby-prof', platform: :mri
end

group :test do
	gem 'pry'
	gem 'covered', require: 'covered/rspec' if RUBY_VERSION >= "2.6.0"
	
	gem 'async-process', '~> 1.1.0'
	
	gem 'puma'
end
