# Rails Integration

This guide explains how to host Rails applications with Falcon.

## Integration with Rails

Because `rails` apps are built on top of `rack`, they are compatible with `falcon`.

1. Add `gem 'falcon'` to your `Gemfile` and perhaps remove `gem 'puma'` once you are satisfied with the change.
2. Run `falcon serve` to start a local development server.

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
