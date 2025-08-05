# Getting Started

This guide gives an overview of how to use Falcon for running Ruby web applications.

## Installation

Add the gem to your project:

~~~ bash
$ bundle add falcon
~~~

Or, if you prefer, install it globally:

~~~ bash
$ gem install falcon
~~~

## Core Concepts

Falcon is a high-performance web server for Ruby. It is designed to be fast, lightweight, and easy to use.

- **Asynchronous**: Falcon is built on top of the fiber scheduler and the [async gem](https://github.com/socketry/async) which allow it to handle thousands of connections concurrently.
- **Rack Compatible**: Falcon is a Rack server. It can run any Rack application, including Rails, Sinatra, and Roda with no modifications.
- **Secure**: Falcon supports TLS out of the box. It can generate self-signed certificates for localhost.
- **HTTP/2**: Falcon is build on top of the [async-http gem](https://github.com/socketry/async-http) which supports HTTP/2. It can serve multiple requests over a single connection.
- **WebSockets**: Falcon supports WebSockets using the [async-websocket gem](https://github.com/socketry/async-websocket) which takes advantage of Rack 3 streaming responses. You can build complex real-time applications with ease.

### Rack

Falcon is a Rack server. This means it can run any Rack application, including Rails, Sinatra, and Roda. It is compatible with the Rack 2 and Rack 3 specifications. Typically these applications have a `config.ru` file that defines the application. Falcon can run these applications directly:

~~~ ruby
# config.ru

run do |env|
	[200, {'Content-Type' => 'text/plain'}, ['Hello, World!']]
end
~~~

Then run the application with:

~~~ bash
$ falcon serve
~~~

## Running a Local Server

For local application development, you can use the `falcon serve` command. This will start a local server on `https://localhost:9292`. Falcon generates self-signed certificates for `localhost`. This allows you to test your application with HTTPS locally.

To run on a different port:

~~~ bash
$ falcon serve --port 3000
~~~

### Unencrypted HTTP

If you want to run Falcon without TLS, you can use the `--bind` option to bind to an unencrypted HTTP endpoint:

~~~ bash
$ falcon serve --bind http://localhost:3000
~~~

### Using with Rackup

You can invoke Falcon via `rackup`:

~~~ bash
$ rackup --server falcon
~~~

This will run a single-threaded instance of Falcon using `http/1`. While it works fine, it's not recommended to use `rackup` with `falcon`, because performance will be limited.
