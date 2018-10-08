# ![Falcon](logo.svg)

Falcon is a multi-process, multi-fiber rack-compatible HTTP server built on top of [async], [async-io], [async-container] and [async-http]. Each request is run within a light weight fiber and can block on up-stream requests without stalling the entire server process. Supports HTTP/1 and HTTP/2 natively. [Priority Business Support](#business-support) is available.

[![Build Status](https://secure.travis-ci.org/socketry/falcon.svg)](http://travis-ci.org/socketry/falcon)
[![Code Climate](https://codeclimate.com/github/socketry/falcon.svg)](https://codeclimate.com/github/socketry/falcon)
[![Coverage Status](https://coveralls.io/repos/socketry/falcon/badge.svg)](https://coveralls.io/r/socketry/falcon)

[async]: https://github.com/socketry/async
[async-io]: https://github.com/socketry/async-io
[async-container]: https://github.com/socketry/async-container
[async-http]: https://github.com/socketry/async-http

## Motivation

When I initially built [async], I saw an opportunity to build [async-http], which provides both client and server components. After toying with these ideas, I decided to build an actual web server, primarily out of interest to compare and validate performance. Falcon grew out of those experiments, and allowed me to test existing real-world code on top of [async].

Once I had something working, I saw an opportunity to simplify my development, testing and production environments, replacing production (Nginx+Passenger) and development (Puma) with Falcon. Not only does this simplify deployment, it helps minimize environment-specific bugs.

My long term vision for Falcon is to make a web application platform which trivializes server deployment. Ideally, a web application can fully describe all it's components: HTTP servers, databases, periodic jobs, background jobs, remote management, etc. Currently, it is not uncommon for all these facets to be handled independently, in platform specific ways, which can make it difficult both to set up new instances, as well as make changes to underlying infrastructure. I hope Falcon can address some of these issues in a platform agnostic way.

As web development is something I'm passionate about, having a server like Falcon is empowering.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'falcon'
```

And then execute:

	$ bundle

Or install it yourself as:

	$ gem install falcon

## Usage

You can run `falcon serve` directly, and it will load the `config.ru` and start serving on https://localhost:9292.

### Integration with Rails

Falcon works perfectly with `rails` apps.

1. Add `gem 'falcon'` to your `Gemfile` and perhaps remove `gem 'puma'` once you are satisfied with the change.

2. Run `falcon serve` to start a local development server.

Alternatively run `RACK_HANDLER=falcon rails server` to start the server (at least, until [rack#181](https://github.com/rack/rack/pull/1181) is merged).

#### Thread Safety (Rails < 5.x)

With older versons of Rails, the `Rack::Lock` middleware is inserted into your app unless you explicitly add `config.threadsafe!`. `Rack::Lock` will cause both poor performance and deadlocks due to the highly concurrent nature of `falcon`. Therefore, please ensure you specify `config.threadsafe!` in your `config/application.rb`:

```ruby
module MySite
	class Application < Rails::Application
		# ...
		
		# Enable threaded mode
		config.threadsafe!
	end
end
```

This became the default in Rails 5 so no change is necessary in this version. Other web frameworks are generally unaffected.

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

## Business Support

Falcon can be an important part of your business or project, both improving performance and saving money. As such, paid business support is available to make every project a success. The agreement will give you:

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
