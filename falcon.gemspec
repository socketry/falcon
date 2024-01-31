# frozen_string_literal: true

require_relative "lib/falcon/version"

Gem::Specification.new do |spec|
	spec.name = "falcon"
	spec.version = Falcon::VERSION
	
	spec.summary = "A fast, asynchronous, rack-compatible web server."
	spec.authors = ["Samuel Williams", "Janko Marohnić", "Bryan Powell", "Claudiu Garba", "Kyle Tam", "Mitsutaka Mimura", "Sho Ito", "Colby Swandale", "Daniel Evans", "Kent Gruber", "Michael Adams", "Mikel Kew", "Nick Janetakis", "Olle Jonsson", "Peter Schrammel", "Santiago Bartesaghi", "Sh Lin", "Tad Thorley", "Tasos Latsas"]
	spec.license = "MIT"
	
	spec.cert_chain  = ['release.cert']
	spec.signing_key = File.expand_path('~/.gem/release.pem')
	
	spec.homepage = "https://github.com/socketry/falcon"
	
	spec.metadata = {
		"documentation_uri" => "https://socketry.github.io/falcon/",
	}
	
	spec.files = Dir.glob(['{bake,bin,lib}/**/*', '*.md'], File::FNM_DOTMATCH, base: __dir__)
	
	spec.executables = ["falcon", "falcon-host"]
	
	spec.required_ruby_version = ">= 3.0"
	
	spec.add_dependency "async"
	spec.add_dependency "async-container", "~> 0.16.0"
	spec.add_dependency "async-http", "~> 0.57"
	spec.add_dependency "async-http-cache", "~> 0.4.0"
	spec.add_dependency "async-io", "~> 1.22"
	spec.add_dependency "build-environment", "~> 1.13"
	spec.add_dependency "bundler"
	spec.add_dependency "localhost", "~> 1.1"
	spec.add_dependency "openssl", "~> 3.0"
	spec.add_dependency "process-metrics", "~> 0.2.0"
	spec.add_dependency "protocol-rack", "~> 0.1"
	spec.add_dependency "samovar", "~> 2.1"
end
