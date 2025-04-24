# Rails Integration

This guide explains how to host Rails applications with Falcon.

## Integration with Rails

Because Rails apps are built on top of Rack, they are compatible with Falcon.

1. Add `gem "falcon"` to your `Gemfile` and perhaps remove `gem "puma"` once you are satisfied with the change.
2. Run `falcon serve` to start a local development server.

We do not recommend using Rails older than v7.1 with Falcon. If you are using an older version of Rails, you should upgrade to the latest version before using Falcon.

Falcon assumes HTTPS by default (so that browsers can use HTTP2). To run under HTTP in development you can bind it to an explicit scheme, host and port:

~~~ bash
falcon serve -b http://localhost:3000
~~~

### Production

The `falcon serve` command is only intended to be used for local development. Follow these steps to run a production Rails app with Falcon:

1. Create a `falcon.rb` file

~~~ rb
#!/usr/bin/env -S falcon host
# frozen_string_literal: true

require "falcon/environment/rack"

hostname = File.basename(__dir__)
port = ENV["PORT"] || 3000

preload "preload.rb"

service hostname do
	include Falcon::Environment::Rack
	endpoint Async::HTTP::Endpoint.parse("http://0.0.0.0:#{port}")
end
~~~

2. Create a `preload.rb` file

~~~ rb
# frozen_string_literal: true

require_relative "config/environment"
~~~

3. Run the production server with `bundle exec falcon host`


## Isolation Level

Rails 7.1 introduced the ability to change its internal isolation level from threads (default) to fibers. When you use `falcon` with Rails, it will automatically set the isolation level to fibers.

Beware that changing the isolation level may increase the utilization of shared resources such as Active Record's connection pool, since you'll likely be running many more fibers than threads. In the future, Rails is likely to adjust connection pool handling so this shouldn't be an issue in practice.

To mitigate the issue in the meantime, you can wrap Active Record calls in a `with_connection` block so they're released at the end of the block, as opposed to the default behavior where Rails keeps the connection checked out until its finished returning the response:

~~~ ruby
ActiveRecord::Base.connection_pool.with_connection do
  Example.find(1)
end
~~~

Alternatively, to retain the default Rails behavior, you can add the following to `config/application.rb` to reset the isolation level to threads, but beware that sharing connections between fibers may result in unexpected errors within Active Record and is not recommended:

~~~ ruby
config.active_support.isolation_level = :thread
~~~

## ActionCable

Falcon supports `rack.hijack` and is compatible with ActionCable. If you use the `async` adapter, you should run Falcon in threaded mode, or in forked mode with `--count 1`. Otherwise, your messaging system will be distributed over several processes with no IPC mechanism. You might like to try out [async-redis](https://github.com/socketry/async-redis) as an asynchronous message bus.
