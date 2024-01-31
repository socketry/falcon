# Rails Integration

This guide explains how to host Rails applications with Falcon.

## Integration with Rails

Because `rails` apps are built on top of `rack`, they are compatible with `falcon`.

1. Add `gem 'falcon'` to your `Gemfile` and perhaps remove `gem 'puma'` once you are satisfied with the change.
2. Run `falcon serve` to start a local development server.

## Isolation Level

Rails 7.1 introduced the ability to change its internal isolation level from threads (default) to fibers. When you use `falcon` with Rails, it will automatically set the isolation level to fibers.

## Thread Safety

With older versions of Rails, the `Rack::Lock` middleware can be inserted into your app by Rails. `Rack::Lock` will cause both poor performance and deadlocks due to the highly concurrent nature of `falcon`. Other web frameworks are generally unaffected.

### Rails 3.x (and older)

Please ensure you specify `config.threadsafe!` in your `config/application.rb`:

~~~ ruby
module MySite
	class Application < Rails::Application
		# ...
		
		# Enable threaded mode
		config.threadsafe!
	end
end
~~~

### Rails 4.x

Please ensure you have `config.allow_concurrency = true` in your configuration.

### Rails 5.x+

This became the default in Rails 5 so no change is necessary unless you explicitly disabled concurrency, in which case you should remove that configuration.

### ActionCable

Falcon supports `rack.hijack` and is compatible with ActionCable. If you use the `async` adapter, you should run Falcon in threaded mode, or in forked mode with `--count 1`. Otherwise, your messaging system will be distributed over several processes with no IPC mechanism. You might like to try out [async-redis](https://github.com/socketry/async-redis) as an asynchronous message bus.
