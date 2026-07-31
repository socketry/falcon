# Dynamic Clusters with Envoy

This guide explains how to run Falcon workers with independently bound endpoints and publish them dynamically to Envoy using xDS.

## When to Use a Cluster

A regular {ruby Falcon::Service::Server} binds one listener and shares it with every worker. This is the simplest design when Falcon accepts connections directly or sits behind a load balancer that targets one stable address.

{ruby Falcon::Service::Cluster} instead gives each worker its own listener. Use it when an external load balancer needs to address, monitor, and remove workers individually. Because workers may bind ephemeral ports or Unix-domain sockets, the load balancer needs a dynamic source of viable endpoints rather than a static address list.

| Service | Listener ownership | Upstream discovery |
| --- | --- | --- |
| `Falcon::Service::Server` | One listener shared by all workers | One stable address |
| `Falcon::Service::Cluster` | One listener per worker | Dynamic worker endpoints |

## Architecture

Each cluster worker can bind to `localhost` with port `0`, allowing the operating system to assign an available port. Falcon describes the bound resource with a {ruby Falcon::Listener}, including its name, scheme, supported protocols, and concrete addresses.

The worker registers that listener with `async-service-supervisor-envoy`. The supervisor publishes the current workers through an xDS control plane, and Envoy uses Endpoint Discovery Service (EDS) updates to maintain the upstream cluster.

Requests arrive at Envoy's stable listener. Envoy selects one of the discovered worker endpoints and forwards the request to it:

```mermaid
flowchart LR
	Client[Client] -->|HTTP on port 10000| Envoy

	subgraph Network[Shared network namespace]
		Envoy[Envoy]

		subgraph Falcon[Falcon container]
			Supervisor[Supervisor and xDS control plane]
			Worker1[Falcon worker 1]
			Worker2[Falcon worker 2]
		end

		Worker1 -.->|Register endpoint| Supervisor
		Worker2 -.->|Register endpoint| Supervisor
		Supervisor -.->|EDS over ADS on port 18000| Envoy
		Envoy -->|HTTP on dynamic port| Worker1
		Envoy -->|HTTP on dynamic port| Worker2
	end
```

## Configuration

Add Falcon and the Envoy supervisor integration to your `gems.rb`:

```ruby
gem "falcon", "~> 0.56.0"
gem "async-service-supervisor-envoy", "~> 0.2"
```

Define a Falcon cluster service and an accompanying supervisor in `falcon.rb`:

```ruby
#!/usr/bin/env async-service
# frozen_string_literal: true

require "async/service/supervisor"
require "async/service/supervisor/envoy"
require "falcon/environment/cluster"

service "cluster" do
	include Falcon::Environment::Cluster
	include Async::Service::Supervisor::Envoy::Supervised
	
	count 2
	
	def url
		"http://localhost:0"
	end
	
	middleware do
		application = proc do |_env|
			body = "Hello from worker #{Process.pid}!\n"
			
			[200, {
				"content-type" => "text/plain",
				"content-length" => body.bytesize.to_s,
			}, [body]]
		end
		
		Falcon::Server.middleware(application, cache: false)
	end
end

service "supervisor" do
	include Async::Service::Supervisor::Environment
	
	monitors do
		[
			Async::Service::Supervisor::Envoy::Monitor.new(
				bind: "http://127.0.0.1:18000",
			),
		]
	end
end
```

The Falcon service name becomes the listener name, so the corresponding Envoy EDS cluster uses `cluster` as its service name. Configure Envoy to receive aggregated discovery updates from the supervisor:

```yaml
node:
  id: falcon-cluster
  cluster: falcon-cluster

dynamic_resources:
  ads_config:
    api_type: GRPC
    transport_api_version: V3
    grpc_services:
      - envoy_grpc:
          cluster_name: xds_cluster

static_resources:
  listeners:
    - name: listener_http
      address:
        socket_address:
          address: 0.0.0.0
          port_value: 10000
      filter_chains:
        - filters:
            - name: envoy.filters.network.http_connection_manager
              typed_config:
                "@type": type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager
                stat_prefix: ingress_http
                route_config:
                  name: local_route
                  virtual_hosts:
                    - name: falcon
                      domains: ["*"]
                      routes:
                        - match:
                            prefix: "/"
                          route:
                            cluster: cluster
                http_filters:
                  - name: envoy.filters.http.router
                    typed_config:
                      "@type": type.googleapis.com/envoy.extensions.filters.http.router.v3.Router

  clusters:
    - name: cluster
      connect_timeout: 1s
      type: EDS
      lb_policy: ROUND_ROBIN
      eds_cluster_config:
        service_name: cluster
        eds_config:
          ads: {}
          resource_api_version: V3

    - name: xds_cluster
      connect_timeout: 1s
      type: STATIC
      load_assignment:
        cluster_name: xds_cluster
        endpoints:
          - lb_endpoints:
              - endpoint:
                  address:
                    socket_address:
                      address: 127.0.0.1
                      port_value: 18000
      typed_extension_protocol_options:
        envoy.extensions.upstreams.http.v3.HttpProtocolOptions:
          "@type": type.googleapis.com/envoy.extensions.upstreams.http.v3.HttpProtocolOptions
          explicit_http_config:
            http2_protocol_options: {}
```

The `xds_cluster` connection uses HTTP/2 because ADS is served over gRPC.

## Worker Registration

When each worker starts:

1. Falcon binds the worker to an available loopback port.
2. The worker registers its concrete addresses and supported protocols with the supervisor.
3. The supervisor's Envoy monitor publishes the current worker endpoints as an EDS resource.
4. Envoy receives the resource over its Aggregated Discovery Service (ADS) connection and updates its upstream cluster.

The listener preserves all addresses returned by the bound endpoint. This allows the same interface to describe IP sockets, Unix-domain sockets, and endpoints with additional addresses.

## Worker Restarts

If a worker exits, its supervisor connection closes and the monitor publishes an EDS update without that endpoint. Falcon restarts the worker, which binds a new available port and registers it. The monitor then publishes another update, and Envoy receives both changes over its existing ADS stream without polling or restarting.

This lifecycle is important when ports are ephemeral or a directory may contain stale Unix-domain socket paths: consumers should use the supervisor's current endpoint state as the source of truth.

## Network Topology

Falcon and Envoy can run in the same network namespace, allowing workers to bind to loopback addresses while remaining reachable by Envoy. With Docker Compose, `network_mode: service:falcon` gives the Envoy service access to Falcon's network namespace, so `127.0.0.1` and `localhost` refer to the same loopback interface for both processes.

Without a shared network namespace, Envoy cannot connect to worker endpoints bound to Falcon's loopback interface. In a different deployment topology, bind workers to an interface that Envoy can reach and apply the appropriate network access controls.
