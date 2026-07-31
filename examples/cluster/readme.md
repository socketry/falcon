# Cluster with Envoy

This example runs a two-worker Falcon cluster behind Envoy using Docker Compose. Falcon publishes each worker's dynamically bound endpoint through the supervisor's xDS control plane. The supervisor also reports per-worker CPU utilization and request throughput using ORCA, allowing Envoy to shift traffic toward workers with more available capacity.

See the [Dynamic Clusters with Envoy](../../guides/cluster-deployment/readme.md) guide for the architecture, endpoint registration lifecycle, and deployment considerations.

## Requirements

- Docker with Compose support.

## Usage

From this directory, build and start Falcon and Envoy:

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
