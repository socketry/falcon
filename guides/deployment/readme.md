# Deployment

This guide explains how to use Falcon in production environments.

Falcon can be deployed into production either as a standalone application server, or as a virtual host routing to multiple applications. Both configurations can run behind a load balancer, but `falcon virtual` is designed to be zero-configuration deployment option.

## Falcon Serve

`falcon serve` is not designed for deployment because the command line interface is not guaranteed to be stable nor does it expose every possible configuration option.

## Falcon Hosts

`falcon host` is designed for deployment, and is the recommended way to deploy Falcon in production. It exposes a well defined interface for configuring services (web applications, job servers, etc).

### Configuration

`falcon host` loads configuration from the `falcon.rb` file in your application directory. This file contains configuration blocks which define how to host the application and any related services. This file should generally be executable and it invokes `falcon host` which starts all defined services.

Here is a basic example which hosts a rack application using :

~~~ ruby
#!/usr/bin/env falcon host
# frozen_string_literal: true

require "falcon/environment/rack"
require "falcon/environment/lets_encrypt_tls"
require "falcon/environment/supervisor"

hostname = File.basename(__dir__)
service hostname do
	include Falcon::Environment::Rack
	include Falcon::Environment::LetsEncryptTLS

	# Insert an in-memory cache in front of the application (using async-http-cache).
	cache true
end

service "supervisor" do
	include Falcon::Environment::Supervisor
end
~~~

These configuration blocks are evaluated using [async-service](https://github.com/socketry/async-service).

### Application Configuration

The environment configuration is defined in the `Falcon::Environment` module. The {ruby Falcon::Environment::Application} environment supports the generic virtual host functionality, but you can customise any parts of the configuration, e.g. to bind a production host to `localhost:3000` using plaintext HTTP/2:

~~~ ruby
#!/usr/bin/env falcon host
# frozen_string_literal: true

require "falcon/environment/rack"
require "falcon/environment/supervisor"

hostname = File.basename(__dir__)
service hostname do
	include Falcon::Environment::Rack
	include Falcon::Environment::LetsEncryptTLS

	endpoint do
		Async::HTTP::Endpoint
			.parse('http://localhost:3000')
			.with(protocol: Async::HTTP::Protocol::HTTP2)
	end
end

service "supervisor" do
	include Falcon::Environment::Supervisor
end
~~~

You can verify this is working using `nghttp -v http://localhost:3000`.

#### Application Configuration Example for Heroku

Building on the examples above, the following is a full configuration example for Heroku:

~~~ bash
# Procfile

web: bundle exec falcon host
~~~

~~~ ruby
# falcon.rb

#!/usr/bin/env -S falcon host
# frozen_string_literal: true

require "falcon/environment/rack"

hostname = File.basename(__dir__)

service hostname do
	include Falcon::Environment::Rack
	
	# By default, Falcon uses Etc.nprocessors to set the count, which is likely incorrect on shared hosts like Heroku.
	# Review the following for guidance about how to find the right value for your app:
	# https://help.heroku.com/88G3XLA6/what-is-an-acceptable-amount-of-dyno-load
	# https://devcenter.heroku.com/articles/deploying-rails-applications-with-the-puma-web-server#workers
	count ENV.fetch("WEB_CONCURRENCY", 1).to_i
	
	# If using count > 1 you may want to preload your app to reduce memory usage and increase performance:
	preload "preload.rb"

	port {ENV.fetch("PORT", 3000).to_i}

	# Heroku only supports HTTP/1.1 at the time of this writing. Review the following for possible updates in the future:
	# https://devcenter.heroku.com/articles/http-routing#http-versions-supported
	# https://github.com/heroku/roadmap/issues/34
	endpoint do
		Async::HTTP::Endpoint
			.parse("http://0.0.0.0:#{port}")
			.with(protocol: Async::HTTP::Protocol::HTTP11)
	end
~~~

~~~ ruby
# preload.rb

# frozen_string_literal: true

require_relative "config/environment"
~~~

## Falcon Virtual

Falcon can replace Nginx as a virtual server for Ruby applications.

~~~ mermaid
graph TD;
	client[Client Browser] -->|TLS + HTTP/2 TCP| proxy["Falcon Proxy (SNI)"];
	proxy -->|HTTP/2 UNIX PIPE| server["Application Server (Rack Compatible)"];
~~~

You need to create a `falcon.rb` configuration in the root of your applications, and start the virtual host:

~~~ bash
cat /srv/http/example.com/falcon.rb
#!/usr/bin/env falcon host
# frozen_string_literal: true

require "falcon/environment/self_signed_tls"
require "falcon/environment/rack"
require "falcon/environment/supervisor"

service "hello.localhost" do
  include Falcon::Environment::SelfSignedTLS
  include Falcon::Environment::Rack
end

service "supervisor" do
  include Falcon::Environment::Supervisor
end

$ falcon virtual /srv/http/*/falcon.rb
~~~

The Falcon virtual server is hard coded to redirect http traffic to https, and will serve each application using an internal SNI-based proxy.
See the [docker example](https://github.com/socketry/falcon-virtual-docker-example).
