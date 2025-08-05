# Rails Integration

This guide explains how to host Rails applications with Falcon.

**We strongly recommend using the latest stable release of Rails with Falcon.**

We now recommend using the `Falcon::Rails` gem for Rails integration. This gem provides a simple way to configure Falcon as the web server for your Rails application, and includes many conveniences for running Rails with Falcon.

~~~
> bundle add falcon-rails
~~~

It also includes detailed documentation for [common tasks and configurations](https://socketry.github.io/falcon-rails/).

## Usage

Because Rails apps are built on top of Rack, they are compatible with Falcon.

1. Add `gem "falcon"` to your `Gemfile` and perhaps remove `gem "puma"` once you are satisfied with the change.
2. Run `falcon serve` to start a local development server.

Falcon assumes HTTPS by default (so that browsers can use HTTP2). To run under HTTP in development you can bind it to an explicit scheme, host and port:

~~~ bash
falcon serve -b http://localhost:3000
~~~

### Self-signed Development Certificates

The [localhost gem](https://github.com/socketry/localhost) is used to generate self-signed certificates for local development. This allows you to run Falcon with HTTPS in development without needing to set up a real certificate authority. However, you must still install the development certificate to avoid security warnings in your browser:

~~~bash
> bundle exec bake localhost:install
~~~

### Production

The `falcon serve` command is only intended to be used for local development. We recommend you use `falcon host` for production deployments.

#### Falcon Host Configuration File

Create a `falcon.rb` file in the root of your Rails application. This file will be used to configure the Falcon server for production. The following example binds HTTP/1 to port 3000 as is common for Rails applications:

~~~ ruby
#!/usr/bin/env -S falcon-host
# frozen_string_literal: true

require "falcon/environment/rack"

hostname = File.basename(__dir__)

service hostname do
	include Falcon::Environment::Rack
	
	# This file will be loaded in the main process before forking.
	preload "preload.rb"
	
	# Default to port 3000 unless otherwise specified.
	port {ENV.fetch("PORT", 3000).to_i}
	
	# Default to HTTP/1.1.
	endpoint do
		Async::HTTP::Endpoint
			.parse("http://0.0.0.0:#{port}")
			.with(protocol: Async::HTTP::Protocol::HTTP11)
	end
end
~~~

#### Preloading Rails

Preloading is a technique used to load your Rails application into memory before forking worker processes. This can significantly improve performance by reducing the time it takes to start each worker.

~~~ ruby
# frozen_string_literal: true

require_relative "config/environment"
~~~

#### Running the Production Server

To run the production server, make sure your `falcon.rb` is executable and then run it:

~~~ bash
> bundle exec falcon.rb
~~~

## Isolation Level

Rails provides the ability to change its internal isolation level from threads (default) to fibers. When you use `falcon` with Rails, it will automatically set the isolation level to fibers as Falcon provides the appropriate Railtie.
