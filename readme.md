# ![Falcon](logo.svg)

Falcon is a multi-process, multi-fiber rack-compatible HTTP server built on top of [async](https://github.com/socketry/async), [async-io](https://github.com/socketry/async-io), [async-container](https://github.com/socketry/async-container) and [async-http](https://github.com/socketry/async-http). Each request is executed within a lightweight fiber and can block on up-stream requests without stalling the entire server process. Falcon supports HTTP/1 and HTTP/2 natively.

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

  - [Getting Started](https://socketry.github.io/falcon/guides/getting-started/index) - This guide explains how to use Falcon for Ruby web application development.

  - [Rails Integration](https://socketry.github.io/falcon/guides/rails-integration/index) - This guide explains how to host Rails applications with Falcon.

  - [Deployment](https://socketry.github.io/falcon/guides/deployment/index) - This guide explains how to use Falcon in production environments.

  - [Extended Features](https://socketry.github.io/falcon/guides/extended-features/index) - This guide explains some of the extended features and functionality of Falcon.

  - [Performance Tuning](https://socketry.github.io/falcon/guides/performance-tuning/index) - This guide explains the performance characteristics of Falcon.

  - [How It Works](https://socketry.github.io/falcon/guides/how-it-works/index) - This guide gives an overview of how Falcon handles an incoming web request.

## Contributing

We welcome contributions to this project.

1.  Fork it.
2.  Create your feature branch (`git checkout -b my-new-feature`).
3.  Commit your changes (`git commit -am 'Add some feature'`).
4.  Push to the branch (`git push origin my-new-feature`).
5.  Create new Pull Request.

### Developer Certificate of Origin

This project uses the [Developer Certificate of Origin](https://developercertificate.org/). All contributors to this project must agree to this document to have their contributions accepted.

### Contributor Covenant

This project is governed by the [Contributor Covenant](https://www.contributor-covenant.org/). All contributors and participants agree to abide by its terms.
