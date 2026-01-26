# Multi-Protocol Server Example

This example demonstrates how to run the same Rack application on multiple endpoints with different protocols using `IO::Endpoint::NamedEndpoints`.

## Overview

The server runs a single application on:
- **Port 8080**: HTTP/1.1 protocol
- **Port 8090**: HTTP/2 protocol

## How It Works

1. **Environment Definitions**: Two separate environment blocks (`http1` and `http2`) define the endpoint configurations with different protocols (`Async::HTTP::Protocol::HTTP1` and `Async::HTTP::Protocol::HTTP2`).

2. **Protocol Evaluators**: The service creates `protocol_http1` and `protocol_http2` evaluators that combine the environment configurations with the service middleware.

3. **NamedEndpoints**: The service uses `IO::Endpoint::NamedEndpoints` to combine both endpoints into a single object that can be iterated, mapping `protocol_http1` and `protocol_http2` to their respective endpoints.

4. **Custom `make_server`**: The service overrides `make_server` to handle the `NamedEndpoints` object:
   - Iterates over each named endpoint using `bound_endpoint.each`
   - Creates a `Falcon::Server` for each using `self[name].make_server(endpoint)`
   - Combines them using `Falcon::CompositeServer`

## Running

```bash
cd examples/multi-protocol
falcon host
```

## Testing

Test both endpoints:

```bash
# HTTP/1.1 on port 8080
curl http://localhost:8080/

# HTTP/2 on port 8090 (plaintext)
curl --http2-prior-knowledge http://localhost:8090/
```

The application will respond with information about which protocol and port it's running on. The `--http2-prior-knowledge` flag is used to connect directly to the HTTP/2 endpoint without protocol negotiation or TLS.
