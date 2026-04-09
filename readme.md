# ![Falcon](assets/logo.webp)

Falcon is a multi-process, multi-fiber rack-compatible HTTP server built on top of [async](https://github.com/socketry/async), [async-container](https://github.com/socketry/async-container) and [async-http](https://github.com/socketry/async-http). Each request is executed within a lightweight fiber and can block on up-stream requests without stalling the entire server process. Falcon supports HTTP/1 and HTTP/2 natively.

[![Development Status](https://github.com/socketry/falcon/workflows/Test/badge.svg)](https://github.com/socketry/falcon/actions?workflow=Test)

## Motivation

Initially, when I developed [async](https://github.com/socketry/async), I saw an opportunity to implement [async-http](https://github.com/socketry/async-http): providing both client and server components. After experimenting with these ideas, I decided to build an actual web server for comparing and validating performance primarily out of interest. Falcon grew out of those experiments and permitted the ability to test existing real-world code on top of [async](https://github.com/socketry/async).

Once I had something working, I saw an opportunity to simplify my development, testing and production environments, replacing production (Nginx+Passenger) and development (Puma) with Falcon. Not only does this simplify deployment, it helps minimize environment-specific bugs.

My long term vision for Falcon is to make a web application platform which trivializes server deployment. Ideally, a web application can fully describe all its components: HTTP servers, databases, periodic jobs, background jobs, remote management, etc. Currently, it is not uncommon for all these facets to be handled independently in platform specific ways. This can make it difficult to set up new instances as well as make changes to underlying infrastructure. I hope Falcon can address some of these issues in a platform agnostic way.

As web development is something I'm passionate about, having a server like Falcon is empowering.

## Priority Business Support

Falcon can be an important part of your business or project, both improving performance and saving money. As such, priority business support is available to make every project a success. The support agreement will give you:

  - Direct support and assistance via Slack and email.
  - Advance notification of bugs and security issues.
  - Priority consideration of feature requests and bug reports.
  - Better software by funding development and testing.

Please visit [Socketry.io](https://socketry.io) to register and subscribe.

## Usage

Please see the [project documentation](https://socketry.github.io/falcon/) for more details.

  - [Getting Started](https://socketry.github.io/falcon/guides/getting-started/index) - This guide gives an overview of how to use Falcon for running Ruby web applications.

  - [Rails Integration](https://socketry.github.io/falcon/guides/rails-integration/index) - This guide explains how to host Rails applications with Falcon.

  - [Deployment](https://socketry.github.io/falcon/guides/deployment/index) - This guide explains how to deploy applications using the Falcon web server. It covers the recommended deployment methods, configuration options, and examples for different environments, including systemd and kubernetes.

  - [Performance Tuning](https://socketry.github.io/falcon/guides/performance-tuning/index) - This guide explains the performance characteristics of Falcon.

  - [WebSockets](https://socketry.github.io/falcon/guides/websockets/index) - This guide explains how to use WebSockets with Falcon.

  - [Interim Responses](https://socketry.github.io/falcon/guides/interim-responses/index) - This guide explains how to use interim responses in Falcon to send early hints to the client.

  - [How It Works](https://socketry.github.io/falcon/guides/how-it-works/index) - This guide gives an overview of how Falcon handles an incoming web request.

## Releases

Please see the [project releases](https://socketry.github.io/falcon/releases/index) for all releases.

### v0.55.3

  - Decrement `requests_active` in `Falcon::Server#call` when `super` or `Falcon::Body::RequestFinished.wrap` raises, so utilization metrics are not leaked on error paths.

### v0.55.2

  - Remove unnecessary require for `async/service/supervisor/supervised`.

### v0.55.1

  - `requests_active` is decremented after the response body is closed, including `rack.response_finished` callbacks.

### v0.55.0

  - **Breaking**: Drop dependency on `async-container-supervisor`, you should migrate to `async-service-supervisor` instead.
  - **Breaking**: Remove support for legacy environments, including `Falcon::Configuration`, now using `Async::Service::Configuration` directly.
  - **Breaking**: `bake falcon:supervisor:restart` removed – superceeded by `async:service:supervisor:restart`.
  - Add support for `async-utilization` metrics.

### v0.54.1

  - Fix handling of old style supervisors from `Async::Container::Supervisor`.

### v0.54.0

  - Introduce `Falcon::CompositeServer` for hosting multiple server instances in a single worker.

### v0.52.4

  - Relax dependency on `async-container-supervisor` to allow `~> 0.6`.

### v0.52.0

  - Modernized codebase and dropped support for Ruby v3.1.
  - Improved Rails integration documentation.
  - Added extra logging of `RUBY_DESCRIPTION`.
  - Minor documentation improvements.
  - Agent context is now available, via the [`agent-context` gem](https://github.com/ioquatix/agent-context).

### v0.51.0

  - Introduce <code class="language-ruby">Falcon::Environment::Server\#make\_server</code> which gives you full control over the server creation process.
  - [Introduce `Async::Container::Supervisor`.](https://socketry.github.io/falcon/releases/index#introduce-async::container::supervisor.)

### v0.50.0

  - Add <code class="language-ruby">Falcon::Environment::Server\#endpoint\_options</code> to allow configuration of the endpoint options more easily.

## Contributing

We welcome contributions to this project.

1.  Fork it.
2.  Create your feature branch (`git checkout -b my-new-feature`).
3.  Commit your changes (`git commit -am 'Add some feature'`).
4.  Push to the branch (`git push origin my-new-feature`).
5.  Create new Pull Request.

### Developer Certificate of Origin

In order to protect users of this project, we require all contributors to comply with the [Developer Certificate of Origin](https://developercertificate.org/). This ensures that all contributions are properly licensed and attributed.

### Community Guidelines

This project is best served by a collaborative and respectful environment. Treat each other professionally, respect differing viewpoints, and engage constructively. Harassment, discrimination, or harmful behavior is not tolerated. Communicate clearly, listen actively, and support one another. If any issues arise, please inform the project maintainers.
