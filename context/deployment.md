# Deployment

This guide explains how to use Falcon in production environments.

Falcon can be deployed into production either as a standalone application server, or as a virtual host routing to multiple applications. Both configurations can run behind a load balancer, but `falcon virtual` is designed to be zero-configuration deployment option.

## Falcon Serve

`falcon serve` is not designed for deployment because the command line interface is not guaranteed to be stable nor does it expose every possible configuration option.

## Falcon Hosts

`falcon host` is designed for deployment, and is the recommended way to deploy Falcon in production. It exposes a well defined interface for configuring services (web applications, job servers, etc).

### Configuration

`falcon host` loads configuration from the `falcon.rb` file in your application directory. This file contains configuration blocks which define how to host the application and any related services. This file should be executable and it invokes `falcon-host` which starts all defined services.

Here is a basic example which hosts a rack application using :

~~~ ruby
#!/usr/bin/env falcon-host
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

These configuration blocks are evaluated using the [async-service](https://github.com/socketry/async-service) gem. The supervisor is an independent service which monitors the health of the application and can restart it if necessary. Other services like background job processors can be added to the configuration.

### Environments

The service blocks define configuration that is loaded by the serivce layer to control how the service is run. The `service ... do` block defines the service name and the environment in which it runs. Different modules can be included to provide different functionality, such as `Falcon::Environment::Rack` for Rack applications, or `Falcon::Environment::LetsEncryptTLS` for automatic TLS certificate management.

## Falcon Virtual

Falcon virtual provides a virtual host proxy and HTTP-to-HTTPS redirection for multiple applications. It is designed to be a zero-configuration deployment option, allowing you to run multiple applications on the same server.

You need to create a `falcon.rb` configuration in the root of your applications, and start the virtual host:

~~~ bash
falcon virtual /srv/http/*/falcon.rb
~~~

By default, it binds to both HTTP and HTTPS ports, and automatically redirects HTTP requests to HTTPS. It also supports automatic TLS certificate management using Let's Encrypt.

See the [docker example](https://github.com/socketry/falcon-virtual-docker-example) for a complete working example.
