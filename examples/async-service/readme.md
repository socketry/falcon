# Async::Service

Async::Service provides a generic service layer for managing the lifecycle of services.

Falcon provides several services which are managed by the service layer, including:

- `Falcon::Service::Server`: An HTTP server.
- `Falcon::Service::Supervisor`: A process supervisor (memory usage, etc).

The service layer can support multiple different services, and can be used to manage the lifecycle of any service, or group of services.

This simple example shows how to use `async-service` to start a web server.

``` shell
$ bundle exec async-service ./hello.rb
```

This will start a web server on port 9292 which responds with "Hello World!" to all requests.
