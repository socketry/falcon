# Falcon For Deployment

This guide explains how to use falcon for deployment.

Falcon can be deployed into production either as a standalone application server, or as a virtual host routing to multiple applications.

## Falcon Serve

`falcon serve` is not designed for deployment. As a command, it's designed around the needs of development.

## Falcon Hosts

`falcon host` is designed for deployment.

### Configuration

`falcon host` loads configuration from the `falcon.rb` file in your application directory. This file contains configuration blocks which define how to host the application and any related services. This file should generally be executable and it invokes `falcon host` which starts all defined services.

Here is basic example which hosts a rack application:

~~~ ruby
#!/usr/bin/env -S falcon host
# frozen_string_literal: true

load :rack, :lets_encrypt_tls, :supervisor

hostname = File.basename(__dir__)
rack hostname, :lets_encrypt_tls do
	cache true
end

supervisor
~~~

These configuration blocks are constructed using [build-environment](https://github.com/ioquatix/build-environment), and the defaults are listed in the [falcon source code](https://github.com/socketry/falcon/tree/master/lib/falcon/configuration).

### Application Configuration

The [`rack` environment](https://github.com/socketry/falcon/blob/master/lib/falcon/configuration/rack.rb) inherits the [application environment](https://github.com/socketry/falcon/blob/master/lib/falcon/configuration/application.rb). These environments by default are defined for usage with `falcon virtual`, but you can customise any parts of the configuration, e.g. to bind a production host to `localhost:3000` using plaintext HTTP/2:

~~~ ruby
#!/usr/bin/env -S falcon host
# frozen_string_literal: true

load :rack, :supervisor

hostname = File.basename(__dir__)
rack hostname do
	endpoint Async::HTTP::Endpoint.parse('http://localhost:3000').with(protocol: Async::HTTP::Protocol::HTTP2)
end

supervisor
~~~

You can verify this is woring using `nghttp -v http://localhost:3000`.

## Falcon Virtual

Falcon can replace Nginx as a virtual server for Ruby applications. **This is an experimental feature**.

~~~
/--------------------\
|   Client Browser   |
\--------------------/
          ||          
  (TLS + HTTP/2 TCP)
          ||          
/--------------------\
| Falcon Proxy (SNI) |
\--------------------/
          ||          
  (HTTP/2 UNIX PIPE)
          ||          
/--------------------\
| Application Server |   (Rack Compatible)
\--------------------/	
~~~

You need to create a `falcon.rb` configuration in the root of your applications, and start the virtual host:

~~~ bash
$ cat /srv/http/example.com/falcon.rb
#!/usr/bin/env -S falcon host

load :rack, :lets_encrypt_tls, :supervisor

rack 'hello.localhost', :lets_encrypt_tls

supervisor

$ falcon virtual /srv/http/example.com/falcon.rb
~~~

The falcon virtual server is hard coded to redirect http traffic to https, and will serve each application using an internal SNI-based proxy.
