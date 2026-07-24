# Cluster TCP Endpoints

This example shows how to run Falcon cluster workers on independently bound TCP endpoints. Each worker binds to `localhost` with port `0`, allowing the operating system to assign an available port.

After binding, Falcon describes each worker using a `Falcon::Service::Cluster::Listener`. The listener exposes its logical name, scheme, supported protocol names, bound endpoint, and all concrete socket addresses. This example records those addresses in `addresses.txt`; service discovery integrations can instead use `prepare_worker!(instance, listener:)` to register them directly.

## Usage

Start the two-worker cluster:

```shell
$ bundle exec async-service ./falcon.rb
```

In another terminal, run the client:

```shell
$ bundle exec ruby ./client.rb
[::]:53142: Hello World!
[::]:53143: Hello World!
```

The exact address family and ports are platform-dependent.

Both commands use `./addresses.txt` by default. Set `ADDRESSES_PATH` on both commands to use a different file:

```shell
$ ADDRESSES_PATH=/tmp/falcon-cluster-addresses bundle exec async-service ./falcon.rb
$ ADDRESSES_PATH=/tmp/falcon-cluster-addresses bundle exec ruby ./client.rb
```
