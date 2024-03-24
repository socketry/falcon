# Getting Started

This guide explains how to use Falcon for Ruby web application development.

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

### Using with Rackup

You can invoke Falcon via `rackup`:

~~~ bash
$ rackup --server falcon
~~~

This will run a single-threaded instance of Falcon using `http/1`. While it works fine, it's not recommended to use `rackup` with `falcon`, because performance will be limited.

### Self-Signed TLS with Curl

In order to use `curl` with self-signed localhost certificates, you need to specify `--insecure` or the path of the certificate to validate the request:

~~~
> curl -v https://localhost:9292 --cacert ~/.localhost/localhost.crt
*   Trying ::1...
* TCP_NODELAY set
* Connected to localhost (::1) port 9292 (#0)
* ALPN, offering http/1.1
* Cipher selection: ALL:!EXPORT:!EXPORT40:!EXPORT56:!aNULL:!LOW:!RC4:@STRENGTH
* successfully set certificate verify locations:
*   CAfile: /Users/samuel/.localhost/localhost.crt
  CApath: none
* TLSv1.2 (OUT), TLS header, Certificate Status (22):
* TLSv1.2 (OUT), TLS handshake, Client hello (1):
* TLSv1.2 (IN), TLS handshake, Server hello (2):
* TLSv1.2 (IN), TLS handshake, Certificate (11):
* TLSv1.2 (IN), TLS handshake, Server key exchange (12):
* TLSv1.2 (IN), TLS handshake, Request CERT (13):
* TLSv1.2 (IN), TLS handshake, Server finished (14):
* TLSv1.2 (OUT), TLS handshake, Certificate (11):
* TLSv1.2 (OUT), TLS handshake, Client key exchange (16):
* TLSv1.2 (OUT), TLS change cipher, Change cipher spec (1):
* TLSv1.2 (OUT), TLS handshake, Finished (20):
* TLSv1.2 (IN), TLS change cipher, Change cipher spec (1):
* TLSv1.2 (IN), TLS handshake, Finished (20):
* SSL connection using TLSv1.2 / ECDHE-RSA-AES256-GCM-SHA384
* ALPN, server accepted to use http/1.1
* Server certificate:
*  subject: O=Development/CN=localhost
*  start date: Aug 10 00:31:43 2018 GMT
*  expire date: Aug  7 00:31:43 2028 GMT
*  subjectAltName: host "localhost" matched cert's "localhost"
*  issuer: O=Development/CN=localhost
*  SSL certificate verify ok.
> GET / HTTP/1.1
> Host: localhost:9292
> User-Agent: curl/7.63.0
> Accept: */*
> 
< HTTP/1.1 301
< location: /index
< cache-control: max-age=86400
< content-length: 0
< 
* Connection #0 to host localhost left intact
~~~
