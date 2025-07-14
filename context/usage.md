# Usage

Falcon is a high-performance web server designed for Ruby applications, particularly those that require efficient handling of both asynchronous I/O and CPU-bound tasks. This guide provides an overview of how to use Falcon effectively, especially in scenarios involving concurrent processing.

## Overview

Falcon operates by creating a server that can handle multiple requests concurrently, leveraging Ruby's async capabilities. It is built on top of the `async` gem and integrates with Rack applications, allowing for seamless handling of web requests.

## Rack Support

Falcon supports traditional Rack applications, enabling developers to run existing Ruby web frameworks (like Sinatra or Rails) with minimal changes. It wraps the incoming HTTP requests and responses, allowing for a consistent interface across different types of applications.

```
# config.ru

run do |env|
	[200, { 'Content-Type' => 'text/plain' }, ['Hello from Falcon!']]
end
```

You can run this application using Falcon by executing:

```bash
falcon serve
```

Falcon itself supports HTTP/2 by default, which requires the use of TLS. To do this, it uses the `localhost` gem which creates self-signed certificates for local development.

### Un-encrypted HTTP

Falcon can also run unencrypted HTTP for development purposes. To do this, you can specify the `--bind` option when starting the server:

```bash
falcon serve --bind http://localhost:9292
```
