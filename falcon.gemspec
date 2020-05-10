
require_relative 'lib/falcon/version'

Gem::Specification.new do |spec|
	spec.name = "falcon"
	spec.version = Falcon::VERSION
	spec.authors = ["Samuel Williams"]
	spec.email = ["samuel.williams@oriontransfer.co.nz"]
	
	spec.summary = "A fast, asynchronous, rack-compatible web server."
	spec.homepage = "https://github.com/socketry/falcon"
	
	spec.required_ruby_version = "~> 2.5"
	
	spec.files = Dir['{bake,bin,lib}/**/*', base: __dir__]
	spec.require_paths = ['lib']
	
	spec.executables = ['falcon', 'falcon-host']
	
	spec.add_dependency "async", "~> 1.13"
	spec.add_dependency "async-io", "~> 1.22"
	spec.add_dependency "async-http", "~> 0.52.0"
	spec.add_dependency "async-http-cache", "~> 0.2.0"
	spec.add_dependency "async-container", "~> 0.16.0"
	
	spec.add_dependency "rack", ">= 1.0"
	
	spec.add_dependency 'samovar', "~> 2.1"
	spec.add_dependency 'localhost', "~> 1.1"
	spec.add_dependency 'build-environment', '~> 1.13'
	
	spec.add_dependency 'process-metrics', '~> 0.2.0'
	
	spec.add_development_dependency "async-rspec", "~> 1.7"
	spec.add_development_dependency "async-websocket", "~> 0.14.0"
	spec.add_development_dependency "async-process", "~> 1.1"
	
	spec.add_development_dependency "utopia-project"
	
	spec.add_development_dependency "bake"
	spec.add_development_dependency "covered"
	spec.add_development_dependency "bundler"
	spec.add_development_dependency "rspec", "~> 3.6"
	spec.add_development_dependency "bake-bundler"
end
