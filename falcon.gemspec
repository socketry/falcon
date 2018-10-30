
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

	spec.add_dependency("http-protocol", "~> 0.9.0")

	spec.add_dependency("async-io", "~> 1.9")
	spec.add_dependency("async-http", "~> 0.37.0")
	spec.add_dependency("async-container", "~> 0.8.0")
	
	spec.add_dependency("rack", ">= 1.0")
	
	spec.add_dependency('samovar', "~> 1.3")
	spec.add_dependency('localhost', "~> 1.1")
	
	spec.add_development_dependency "async-rspec", "~> 1.7"
	spec.add_development_dependency "async-websocket", "~> 0.6.0"
	
	spec.add_development_dependency "bundler", "~> 1.3"
	spec.add_development_dependency "rspec", "~> 3.6"
	spec.add_development_dependency "rake"
end
