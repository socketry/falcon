# ![Falcon](logo.svg)

Falcon is a multi-process, multi-fiber rack-compatible HTTP server built on top of [async], [async-io], [async-container] and [async-http]. Each request is executed within a lightweight fiber and can block on up-stream requests without stalling the entire server process. Falcon supports HTTP/1 and HTTP/2 natively.

[Priority Business Support](#priority-business-support) is available.

[![Build Status](https://travis-ci.com/socketry/falcon.svg)](http://travis-ci.com/socketry/falcon)
[![Code Climate](https://codeclimate.com/github/socketry/falcon.svg)](https://codeclimate.com/github/socketry/falcon)
[![Coverage Status](https://coveralls.io/repos/socketry/falcon/badge.svg)](https://coveralls.io/r/socketry/falcon)
[![Gitter](https://badges.gitter.im/join.svg)](https://gitter.im/socketry/falcon)

[async]: https://github.com/socketry/async
[async-io]: https://github.com/socketry/async-io
[async-container]: https://github.com/socketry/async-container
[async-http]: https://github.com/socketry/async-http

## Motivation

Initially, when I developed [async], I saw an opportunity to implement [async-http]: providing both client and server components. After experimenting with these ideas, I decided to build an actual web server for comparing and validating performance primarily out of interest. Falcon grew out of those experiments and permitted the ability to test existing real-world code on top of [async].

Once I had something working, I saw an opportunity to simplify my development, testing and production environments, replacing production (Nginx+Passenger) and development (Puma) with Falcon. Not only does this simplify deployment, it helps minimize environment-specific bugs.

My long term vision for Falcon is to make a web application platform which trivializes server deployment. Ideally, a web application can fully describe all it's components: HTTP servers, databases, periodic jobs, background jobs, remote management, etc. Currently, it is not uncommon for all these facets to be handled independently in platform specific ways. This can make it difficult to set up new instances as well as make changes to underlying infrastructure. I hope Falcon can address some of these issues in a platform agnostic way.

As web development is something I'm passionate about, having a server like Falcon is empowering.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'falcon'
```

And then execute:

	$ bundle

Alternatively, install in terminal:

	$ gem install falcon

## Usage

You can run `falcon serve` directly. It will load the `config.ru` and start serving on https://localhost:9292.

The `falcon serve` command has the following options for you to use:

```
$ falcon --help
falcon [--verbose | --quiet] [-h/--help] [-v/--version] <command>
	An asynchronous HTTP client/server toolset.

	[--verbose | --quiet]  Verbosity of output for debugging.
	[-h/--help]            Print out help information.
	[-v/--version]         Print out the application version.
	<command>              One of: serve, virtual.             Default: serve

	serve [-b/--bind <address>] [-p/--port <number>] [-h/--hostname <hostname>] [-c/--config <path>] [-n/--concurrency <count>] [--forked | --threaded]
		Run an HTTP server.

		[-b/--bind <address>]       Bind to the given hostname/address                               Default: https://localhost:9292
		[-p/--port <number>]        Override the specified port 
		[-h/--hostname <hostname>]  Specify the hostname which would be used for certificates, etc.
		[-c/--config <path>]        Rackup configuration file to load                                Default: config.ru 
		[-n/--concurrency <count>]  Number of processes to start                                     Default: 8 
		[--forked | --threaded]     Select a specific concurrency model                              Default: forked
```

To run on a different port:

```
$ falcon serve --port 3000
```

### Integration with Rails

Falcon works perfectly with `rails` apps.

1. Add `gem 'falcon'` to your `Gemfile` and perhaps remove `gem 'puma'` once you are satisfied with the change.

2. Run `falcon serve` to start a local development server.

Alternatively run `RACK_HANDLER=falcon rails server` to start the server (at least, until [rack#181](https://github.com/rack/rack/pull/1181) is merged).

#### Thread Safety

With older versions of Rails, the `Rack::Lock` middleware can be inserted into your app by Rails. `Rack::Lock`will cause both poor performance and deadlocks due to the highly concurrent nature of `falcon`. Other web frameworks are generally unaffected.

##### Rails 3.x (and older)

Please ensure you specify `config.threadsafe!` in your `config/application.rb`:

```ruby
module MySite
	class Application < Rails::Application
		# ...
		
		# Enable threaded mode
		config.threadsafe!
	end
end
```
##### Rails 4.x

Please ensure you have `config.allow_concurrency = true` in your configuration.

##### Rails 5.x+

This became the default in Rails 5 so no change is necessary unless you explicitly disabled concurrency, in which case you should remove that configuration.

### WebSockets

Falcon supports `rack.hijack` for HTTP/1.x connections. You can thus use [async-websocket] in any controller layer to serve WebSocket connections.

[async-websocket]: https://github.com/socketry/async-websocket

#### ActionCable

The `rack.hijack` functionality is compatible with ActionCable. If you use the `async` adapter, you should run falcon in threaded mode, or in forked mode with `--concurrency 1`. Otherwise, your messaging system will be distributed over several processes with no IPC mechanism. You might like to try out [async-redis](https://github.com/socketry/async-redis) as an asynchronous message bus.

### Integration with Guard

Falcon can restart very quickly and is ideal for use with guard. See [guard-falcon] for more details.

[guard-falcon]: https://github.com/socketry/guard-falcon

### Integration with Capybara

Falcon can run in the same process on a different thread, so it's great for use with Capybara (and shared ActiveRecord transactions). See [falcon-capybara] for more details.

[falcon-capybara]: https://github.com/socketry/falcon-capybara

### Using with Rackup

You can invoke Falcon via `rackup`:

	rackup --server falcon

This will run a single-threaded instance of Falcon using `http/1`. While it works fine, it's not recommended to use `rackup` with `falcon`, because performance will be limited.

## Performance

Falcon uses an asynchronous event-driven reactor to provide non-blocking IO. It can handle an arbitrary number of in-flight requests with minimal overhead per request.

It uses one Fiber per request, which yields in the presence of blocking IO.

- [Improving Ruby Concurrency](https://www.codeotaku.com/journal/2018-06/improving-ruby-concurrency/index#performance) – Comparison of Falcon and Puma.

### Memory Usage

Falcon uses a pre-fork model which loads the entire rack application before forking. This reduces per-process memory usage. 

[async-http] has been designed carefully to minimize IO related garbage. This avoids large per-request memory allocations or disk usage, provided that you use streaming IO.

### Self-Signed TLS with Curl

In order to use `curl` with self-signed localhost certificates, you need to specify `--insecure` or the path of the certificate to validate the request:

```
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
```

## Priority Business Support

Falcon can be an important part of your business or project, both improving performance and saving money. As such, priority business support is available to make every project a success. The agreement will give you:

- Better software by funding development and testing.
- Access to "Stretch" goals as outlined below.
- Advance notification of bugs and security issues.
- Priority consideration of feature requests and bug reports.
- Private support and assistance via direct email.

The standard price for business support is $120.00 USD / year / production instance (including reserve instances). Please [contact us](mailto:context@oriontransfer.net?subject=Falcon%20Business%20Support) for more details.

### "Stretch" Goals

Each paying business customer is entitled to one vote to prioritize the below work.

- Add support for push promises and stream prioritization in [async-http].
- Add support for rolling restarts in [async-container].
- Add support for hybrid process/thread model in [async-container].
- Asynchronous Postgres and MySQL database adapters for ActiveRecord in [async-postgres] and [async-mysql].

[async-http]: https://github.com/socketry/async-http
[async-container]: https://github.com/socketry/async-container
[async-postgres]: https://github.com/socketry/async-postgres
[async-mysql]: https://github.com/socketry/async-mysql

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

### Donations

If you want to donate to this project, you may do so using [BitCoin](https://www.blockchain.com/btc/payment_request?address=1BU3RnjB7fS9XmiTHgbmLKL36S5kccovs8). All money donated this way will be used to further development of this and related open source projects.

### Responsible Disclosure

We take the security of our systems seriously, and we value input from the security community. The disclosure of security vulnerabilities helps us ensure the security and privacy of our users. If you believe you've found a security vulnerability in one of our products or platforms please [tell us via email](mailto:security@oriontransfer.net).

## License

Released under the MIT license.

Copyright, 2018, by [Samuel G. D. Williams](http://www.codeotaku.com/samuel-williams).

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
