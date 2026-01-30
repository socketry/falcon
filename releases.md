# Releases

## v0.54.1

  - Fix handling of old style supervisors from `Async::Container::Supervisor`.

## v0.54.0

  - Introduce `Falcon::CompositeServer` for hosting multiple server instances in a single worker.

## v0.52.4

  - Relax dependency on `async-container-supervisor` to allow `~> 0.6`.

## v0.52.0

  - Modernized codebase and dropped support for Ruby v3.1.
  - Improved Rails integration documentation.
  - Added extra logging of `RUBY_DESCRIPTION`.
  - Minor documentation improvements.
  - Agent context is now available, via the [`agent-context` gem](https://github.com/ioquatix/agent-context).

## v0.51.0

  - Introduce {ruby Falcon::Environment::Server\#make\_server} which gives you full control over the server creation process.

### Introduce `Async::Container::Supervisor`.

`Async::Container::Supervisor` is a new supervisor implementation that replaces Falcon's own supervisor. This allows you to use the same supervisor for all your services, and provides a more consistent interface for managing services. The supervisor is now a separate gem, `async-container-supervisor`.

By default, the supervisor does not perform any monitoring, but you may add monitoring by defining them in the service definition. For example:

``` ruby
service "hello.localhost" do
	# Configure server...
	
	include Async::Container::Supervisor::Supervised
end

service "supervisor" do
	include Async::Container::Supervisor::Environment
	
	monitors do
		[
			# Limit total memory usage to 512MiB:
			Async::Container::Supervisor::MemoryMonitor.new(interval: 10, limit: 1024 * 1024 * 512),
		]
	end
end
```

We retain the `falcon:supervisor:restart` task, but you may prefer to use `async:container:supervisor:restart` directly.

## v0.50.0

  - Add {ruby Falcon::Environment::Server\#endpoint\_options} to allow configuration of the endpoint options more easily.

## v0.49.0

### Falcon Server Container Health Checks

{ruby Falcon::Service::Server} adds support for the {ruby Async::Container} health check which detects hung processes and restarts them. The default health check interval is 30 seconds.

`falcon serve` introduces a new `--health-check-timeout` option to configure the health check timeout. `falcon.rb`/`falcon host` can be changed using the `health_check_timeout` key within the `container_options` configuration - these are passed directly to {ruby Async::Container}. If you don't want a health check, set `health_check_timeout` to `nil`.

### Falcon Server Process Title

The Falcon server process title is now updated periodically (alongside the health check) to include information about the numnber of connections and requests.

    12211 ttys002    0:00.28 /Users/samuel/.gem/ruby/3.4.1/bin/falcon serve --bind http://localhost:8000      
    12213 ttys002    0:04.14 http://localhost:8000 (C=2/2 R=0/49.45K L=0.353)
    12214 ttys002    0:07.22 http://localhost:8000 (C=5/6 R=0/112.97K L=0.534)
    12215 ttys002    0:05.41 http://localhost:8000 (C=3/3 R=0/71.7K L=0.439)
    12216 ttys002    0:06.46 http://localhost:8000 (C=4/5 R=0/93.22K L=0.493)
    12217 ttys002    0:02.58 http://localhost:8000 (C=1/1 R=0/24.9K L=0.251)
    12218 ttys002    0:05.44 http://localhost:8000 (C=3/3 R=0/72.12K L=0.439)
    12219 ttys002    0:06.47 http://localhost:8000 (C=4/4 R=0/93.13K L=0.493)
    12220 ttys002    0:04.03 http://localhost:8000 (C=2/2 R=0/47.37K L=0.357)
    12221 ttys002    0:06.41 http://localhost:8000 (C=4/4 R=0/92.46K L=0.494)
    12222 ttys002    0:06.38 http://localhost:8000 (C=4/4 R=0/91.71K L=0.495)

  - **C** – Connections: `(current/total)` connections accepted by the server
  - **R** – Requests: `(current/total)` requests processed by the server
  - **L** – Scheduler Load: A floating-point value representing the event loop load

Note, if you are using `htop`, you should enable "Setup" → "Display Options" → "\[x\] Update process names on every refresh" otherwise the process title will not be updated.

## v0.48.4

  - Improve compatibility of rackup handler w.r.t. sinatra.

## v0.47.8

  - Fix Falcon Supervisor implementation: due to invalid code, it was unable to start.

# v0.45.0

## Compatibility Fixes

During the `v0.44.0` release cycle, the workflows for testing older rack releases were accidentally dropped. As such, `v0.44.0` was not compatible with older versions of rack. This release restores compatibility with older versions of rack.

Specifically, `protocol-rack` now provides `Protocol::Rack::Adapter.parse_file` to load Rack applications. Rack 2's `Rack::Builder.parse_file` returns both the application and a set of options (multi-value return). Rack 3 changed this to only return the application, as the prior multi-value return was confusing at best. This change allows `protocol-rack` to work with both versions of rack, and `falcon` adopts that interface.

## Falcon Serve Options

In addition, `falcon serve` provides two new options:

1.  `--[no]-restart` which controls what happens when `async-container` instances crash. By default, `falcon serve` will restart the container when it crashes. This can be disabled with `--no-restart`.

2.  `--graceful-stop [timeout]` which allows you to specify a timeout for graceful shutdown. This is useful when you want to stop the server, but allow existing connections to finish processing before the server stops. This feature is highly experimental and doesn't work correctly in all cases yet, but we are aiming to improve it.

# v0.44.0

## Falcon Host

`async-service` is a new gem that exposes a generic service interface on top of `async-container`. Previously, `falcon host` used `async-container` directly and `build-environment` for configuration. In order to allow for more generic service definitions and configuration, `async-service` now provides a similar interface to `build-environment` and exposes this in a way that can be used for services other tha falcon. This makes it simpler to integrate multiple services into a single application.

The current configuration format uses definitions like this:

``` ruby
rack "hello.localhost", :self_signed_tls
```

This changes to:

``` ruby
service "hello.localhost" do
	include Falcon::Environment::Rack
	include Falcon::Environment::SelfSignedTLS
end
```
