# Cluster Unix Sockets

This example shows how to run Falcon cluster workers on independently bound Unix domain sockets. This is useful when a local proxy or service supervisor discovers workers from a socket directory instead of assigning TCP ports.

Each worker lazily constructs an `IO::Endpoint.unix` endpoint using its process ID and current thread object ID. Consequently, process, threaded, and hybrid workers never compete for the same socket path, and the socket directory reflects every independently bound worker.

After binding, Falcon describes each worker using a `Falcon::Service::Cluster::Listener`. The listener exposes its logical name, scheme, protocol, bound endpoint, and all concrete socket addresses. Service discovery integrations can use `prepare_worker!(instance, listener:)` to register exactly what the worker bound.

## Usage

Start the two-worker cluster:

```shell
$ bundle exec async-service ./falcon.rb
```

In another terminal, run the client:

```shell
$ bundle exec ruby ./client.rb
37901-640.ipc: Hello World!
37902-640.ipc: Hello World!
```

Both commands use `./sockets` by default. Set `SOCKET_DIRECTORY` on both commands to use a different directory:

```shell
$ SOCKET_DIRECTORY=/tmp/falcon-cluster bundle exec async-service ./falcon.rb
$ SOCKET_DIRECTORY=/tmp/falcon-cluster bundle exec ruby ./client.rb
```

Unix socket files can remain after a worker exits. Production service discovery should remove stale registrations when it observes the worker exit.
