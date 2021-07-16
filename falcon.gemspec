
require_relative "lib/falcon/version"

Gem::Specification.new do |spec|
	spec.name = "falcon"
	spec.version = Falcon::VERSION
	
	spec.summary = "A fast, asynchronous, rack-compatible web server."
	spec.authors = ["Samuel Williams"]
	spec.license = "MIT"
	
	spec.homepage = "https://github.com/socketry/falcon"
	
	spec.files = Dir.glob('{bake,bin,lib}/**/*', File::FNM_DOTMATCH, base: __dir__)
	
	spec.executables = ["falcon", "falcon-host"]
	
	spec.required_ruby_version = ">= 2.5"
	
	spec.add_dependency "async"
	spec.add_dependency "async-container", "~> 0.16.0"
	spec.add_dependency "async-http", "~> 0.56.0"
	spec.add_dependency "async-http-cache", "~> 0.4.0"
	spec.add_dependency "async-io", "~> 1.22"
	spec.add_dependency "build-environment", "~> 1.13"
	spec.add_dependency "bundler"
	spec.add_dependency "localhost", "~> 1.1"
	spec.add_dependency "process-metrics", "~> 0.2.0"
	spec.add_dependency "rack", ">= 1.0"
	spec.add_dependency "samovar", "~> 2.1"
	
	spec.add_development_dependency "async-process", "~> 1.1"
	spec.add_development_dependency "async-rspec", "~> 1.7"
	spec.add_development_dependency "async-websocket", "~> 0.14.0"
	spec.add_development_dependency "bake"
	spec.add_development_dependency "covered"
	spec.add_development_dependency "rspec", "~> 3.6"
end
