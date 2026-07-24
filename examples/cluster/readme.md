# Cluster with Envoy

This example runs a two-worker Falcon cluster behind Envoy. Each worker binds to `localhost` with port `0`, allowing the operating system to assign an available port. Falcon publishes the concrete worker addresses to Envoy through the supervisor's xDS control plane.

Docker Compose runs Falcon and Envoy in the same network namespace. This allows the workers to remain bound to loopback addresses while Envoy connects to their dynamically assigned ports. Envoy exposes a fixed HTTP listener on port 10000 and distributes requests across the workers.

## Usage

Build and start Falcon and Envoy:

```shell
$ docker compose up --build --detach
```

Run the client through Compose:

```shell
$ docker compose run --rm client
Hello from worker 12!
Hello from worker 13!
```

The client waits for Envoy and confirms that requests reach both workers.

Stop and remove the containers:

```shell
$ docker compose down
```
