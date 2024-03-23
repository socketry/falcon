# Changes

# Unreleased

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
