# Falcon

A multi-process, multi-fiber Rack HTTP server built on top of [async], [async-io] and [async-http]. Each request is run within a light weight fiber and can block on up-stream requests without stalling the entire server process. Uses a multi-process model for handling blocking requests.

[![Build Status](https://secure.travis-ci.org/socketry/falcon.svg)](http://travis-ci.org/socketry/falcon)
[![Code Climate](https://codeclimate.com/github/socketry/falcon.svg)](https://codeclimate.com/github/socketry/falcon)
[![Coverage Status](https://coveralls.io/repos/socketry/falcon/badge.svg)](https://coveralls.io/r/socketry/falcon)

[async]: https://github.com/socketry/async
[async-io]: https://github.com/socketry/async-io
[async-http]: https://github.com/socketry/async-http

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

You can run `falcon` directly, and it will load the `config.ru` and start serving on port 8080.

### Integration with Guard

Falcon can restart very quickly and is ideal for use with guard. See [guard-falcon] for more details.

[guard-falcon]: https://github.com/socketry/guard-falcon

### Integration with Capybara

It is a very fast and light-weight alternative:

```ruby
Capybara.register_server :falcon do |app, port, host|
    require 'async/reactor'
    require 'falcon/server'
    
    Async::Reactor.run do
        server = Falcon::Server.new(app, [Async::IO::Address.tcp(host, port)])
        
        server.run
    end
end
```

### Deploying with Passenger

You can run Falcon within Passenger to improve asyncronicity by using the `Falcon::Hijack` middleware. The first request from a client will be parsed by Passenger, but `rack.hijack` allows us to start parsing requests using Falcon within a separate `Async::Reactor` which reduces latency and avoids blocking IO where possible.

```ruby

if RACK_ENV == :production
  use Falcon::Hijack
end

run MyApp

```

## Performance

Falcon is uses an asynchronous event-driven reactor to provide non-blocking IO. It can handle an arbitrary number of in-flight requests with minimal overhead per request.

It uses one Fiber per request, which yields in the presence of blocking IO.

### Memory Usage

Falcon uses a pre-fork model which loads the entire rack application before forking. This reduces per-process memory usage.

### Throughput

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

Released under the MIT license.

Copyright, 2017, by [Samuel G. D. Williams](http://www.codeotaku.com/samuel-williams).

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
