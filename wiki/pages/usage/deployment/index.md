# Deployment

Falcon can be deployed into production either as a standalone application server, or as a virtual host routing to multiple applications.

## Configuration

In production, `falcon` loads configuration from the `falcon.rb` file in your application directory. This file contains configuration blocks which define how to host the application and any related services. This file should generally be executable and it invokes `falcon host` which starts all defined services.

Here is basic example which hosts a rack application:

```ruby
#!/usr/bin/env -S falcon host
# frozen_string_literal: true

load :rack, :lets_encrypt_tls, :supervisor

hostname = File.basename(__dir__)
rack hostname, :lets_encrypt_tls do
	cache true
end

supervisor
```

These configuration blocks are constructed using [build-environment](https://github.com/ioquatix/build-environment), and the defaults are listed in the [falcon source code](https://github.com/socketry/falcon/tree/master/lib/falcon/configuration).

### Application Configuration

The [`rack` environment](https://github.com/socketry/falcon/blob/master/lib/falcon/configuration/rack.rb) inherits the [application environment](https://github.com/socketry/falcon/blob/master/lib/falcon/configuration/application.rb). These environments by default are defined for usage with `falcon virtual`, but you can customise any parts of the configuration, e.g. to bind a production host to `localhost:3000` using plaintext HTTP/2:

```ruby
#!/usr/bin/env -S falcon host
# frozen_string_literal: true

load :rack, :supervisor

hostname = File.basename(__dir__)
rack hostname do
	endpoint Async::HTTP::Endpoint.parse('http://localhost:3000').with(protocol: Async::HTTP::Protocol::HTTP2)
end

supervisor
```

You can verify this is woring using `nghttp -v http://localhost:3000`.
