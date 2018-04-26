
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

	spec.add_dependency("async-io", "~> 1.6")
	spec.add_dependency("async-http", "~> 0.19.0")
	spec.add_dependency("async-container", "~> 0.5.0")
	
	spec.add_dependency("rack", ">= 1.0")
	
	spec.add_dependency('samovar', "~> 1.3")
	
	spec.add_development_dependency "async-rspec", "~> 1.2"
	
	spec.add_development_dependency "bundler", "~> 1.3"
	spec.add_development_dependency "rspec", "~> 3.6"
	spec.add_development_dependency "rake"
end
