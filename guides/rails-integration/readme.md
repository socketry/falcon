# Rails Integration

This guide explains how to host Rails applications with Falcon.

**We strongly recommend using the latest stable release of Rails with Falcon.** The integration is much smoother and you will benefit from the latest features and bug fixes. This guide is primarily intended for users of Rails 8.0 and later.

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

~~~ ruby
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

~~~ ruby
# frozen_string_literal: true

require_relative "config/environment"
~~~

3. Run the production server with `bundle exec falcon host`


## Isolation Level

Rails provides the ability to change its internal isolation level from threads (default) to fibers. When you use `falcon` with Rails, it will automatically set the isolation level to fibers.

## ActionCable

Falcon fully supports ActionCable with the [`Async::Cable` adapter](https://github.com/socketry/async-cable).

## ActiveJob

Falcon fully supports ActiveJob with the [`Async::Job` adapter](https://github.com/socketry/async-job-adapter-active_job).
