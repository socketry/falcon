
require_relative 'lib/falcon/version'

Gem::Specification.new do |spec|
	spec.name          = "falcon"
	spec.version       = Falcon::VERSION
	spec.authors       = ["Samuel Williams"]
	spec.email         = ["samuel.williams@oriontransfer.co.nz"]

	spec.summary       = "A fast, asynchronous, rack-compatible web server."
	spec.homepage      = "https://github.com/socketry/falcon"

	spec.files         = `git ls-files -z`.split("\x0").reject do |f|
		f.match(%r{^(test|spec|features)/})
	end
	spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
	spec.require_paths = ["lib"]

	spec.add_dependency "http-protocol", "~> 0.17"
	
	spec.add_dependency "async", "~> 1.13"
	spec.add_dependency "async-io", "~> 1.22"
	spec.add_dependency "async-http", "~> 0.38.0"
	spec.add_dependency "async-container", "~> 0.10.0"
	
	spec.add_dependency "rack", ">= 1.0"
	
	spec.add_dependency 'samovar', "~> 2.1"
	spec.add_dependency 'localhost', "~> 1.1"
	spec.add_dependency 'build-environment', '~> 1.6'
	
	spec.add_development_dependency "trenni"
	spec.add_development_dependency "async-rspec", "~> 1.7"
	spec.add_development_dependency "async-websocket", "~> 0.6.0"
	spec.add_development_dependency "async-process", "~> 1.1"
	
	spec.add_development_dependency "covered", "~> 0.10"
	spec.add_development_dependency "bundler"
	spec.add_development_dependency "rspec", "~> 3.6"
	spec.add_development_dependency "rake"
end
