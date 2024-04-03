# Changes

# v0.45.0

## Compatibility Fixes

During the `v0.44.0` release cycle, the workflows for testing older rack releases were accidentally dropped. As such, `v0.44.0` was not compatible with older versions of rack. This release restores compatibility with older versions of rack.

Specifically, `protocol-rack` now provides `Protocol::Rack::Adapter.parse_file` to load Rack applications. Rack 2's `Rack::Builder.parse_file` returns both the application and a set of options (multi-value return). Rack 3 changed this to only return the application, as the prior multi-value return was confusing at best. This change allows `protocol-rack` to work with both versions of rack, and `falcon` adopts that interface.

In addition, `falcon serve` provides two new options:

1. `--[no]-restart` which controls what happens when `async-container` instances crash. By default, `falcon serve` will restart the container when it crashes. This can be disabled with `--no-restart`.

2. `--graceful-stop [timeout]` which allows you to specify a timeout for graceful shutdown. This is useful when you want to stop the server, but allow existing connections to finish processing before the server stops. This feature is highly experimental and doesn't work correctly in all cases yet, but we are aiming to improve it.

# v0.44.0

## Falcon Host

`async-service` is a new gem that exposes a generic service interface on top of `async-container`. Previously, `falcon host` used `async-container` directly and `build-environment` for configuration. In order to allow for more generic service definitions and configuration, `async-service` now provides a similar interface to `build-environment` and exposes this in a way that can be used for services other tha falcon. This makes it simpler to integrate multiple services into a single application.

The current configuration format uses definitions like this:

```ruby
rack 'hello.localhost', :self_signed_tls
```

This changes to:

```ruby
service 'hello.localhost' do
	include Falcon::Environment::Rack
	include Falcon::Environment::SelfSignedTLS
end
```
