# Proxy Example

This example demonstrates how to set up a reverse proxy server using Falcon. The proxy forwards incoming requests to a backend service running on a different endpoint.

## Overview

The example includes two different proxy implementations:

1. **`falcon.rb` + `application.rb`**: A Falcon-native proxy using `Falcon::Environment::Application` that forwards HTTP requests directly.
2. **`config.ru`**: A Rack-based proxy implementation that converts between Rack and Protocol::HTTP formats.

## Architecture

The proxy server:
- Listens on `http://localhost:9292` (configured in `falcon.rb`)
- Forwards all incoming requests to `http://localhost:3000` (the backend service)
- Uses `Async::HTTP::Client` to make upstream requests

## Usage

### Prerequisites

You'll need a backend service running on port 3000. For testing, you can use any HTTP server:

```bash
# In another terminal, start a simple backend server
ruby -run -e httpd . -p 3000
```

### Running the Proxy

Install the dependencies:

```bash
$ bundle install
```

Start the proxy server:

```bash
$ bundle exec falcon host falcon.rb
```

Or using the Rack-based implementation:

```bash
$ bundle exec falcon serve
```

### Testing

Make a request to the proxy server:

```bash
$ curl http://localhost:9292/
```

The proxy will forward the request to `http://localhost:3000` and return the response.

## Configuration

### `falcon.rb`

The `falcon.rb` file configures a Falcon service:
- **Service name**: `proxy.localhost`
- **Endpoint**: `http://localhost:9292`
- **Protocol**: HTTP/1.1
- **Middleware**: Uses the `Application` class from `application.rb`

### `application.rb`

The `Application` class:
- Creates an `Async::HTTP::Client` connected to the backend endpoint
- Forwards all incoming requests to the backend
- Returns the backend's response

### `config.ru`

The Rack-based implementation:
- Uses `Protocol::Rack::Adapter` to convert between Rack and Protocol::HTTP formats
- Demonstrates how to proxy requests when working with Rack applications
- Uses `Thread::Local` to maintain a single client instance per thread

## Customization

To proxy to a different backend, modify the endpoint in `application.rb`:

```ruby
DEFAULT_PROXY_ENDPOINT = Async::HTTP::Endpoint.parse("http://your-backend:port")
```

Or change the port in `falcon.rb`:

```ruby
endpoint do
	Async::HTTP::Endpoint.for(scheme, "localhost", port: 8080, protocol: protocol)
end
```
