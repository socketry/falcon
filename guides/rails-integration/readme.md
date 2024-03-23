# Rails Integration

This guide explains how to host Rails applications with Falcon.

## Integration with Rails

Because `rails` apps are built on top of `rack`, they are compatible with `falcon`.

1. Add `gem 'falcon'` to your `Gemfile` and perhaps remove `gem 'puma'` once you are satisfied with the change.
2. Run `falcon serve` to start a local development server.

We do not recommend using Rails older than v7.1 with `falcon`. If you are using an older version of Rails, you should upgrade to the latest version before using `falcon`.

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
