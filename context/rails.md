# Rails Integration

Falcon can serve Rails applications, however **it is highly recommended to use the latest stable release of Rails** for the best compatibility and performance. This guide explains how to host Rails applications with Falcon.

## Integration with Rails

Because Rails apps are built on top of Rack, they are compatible with Falcon.

1. Add `gem "falcon"` to your `Gemfile` and perhaps remove `gem "puma"` once you are satisfied with the change.
2. Run `falcon serve` to start a local development server.

We do not recommend using Rails older than v7.1 with Falcon. If you are using an older version of Rails, you should upgrade to the latest version before using Falcon.

Falcon assumes HTTPS by default (so that browsers can use HTTP2). To run under HTTP in development you can bind it to an explicit scheme, host and port:

~~~ bash
falcon serve -b http://localhost:3000
~~~

## Isolation Level

Rails provides the ability to change its internal isolation level from threads (default) to fibers. When you use `falcon` with Rails, it will automatically set the isolation level to fibers.

## ActionCable

Falcon fully supports ActionCable with the [`Async::Cable` adapter](https://github.com/socketry/async-cable).

## ActiveJob

Falcon fully supports ActiveJob with the [`Async::Job` adapter](https://github.com/socketry/async-job-adapter-active_job).
