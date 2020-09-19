# ![Falcon](logo.svg)

Falcon is a multi-process, multi-fiber rack-compatible HTTP server built on top of [async](https://github.com/socketry/async), [async-io](https://github.com/socketry/async-io), [async-container](https://github.com/socketry/async-container) and [async-http](https://github.com/socketry/async-http). Each request is executed within a lightweight fiber and can block on up-stream requests without stalling the entire server process. Falcon supports HTTP/1 and HTTP/2 natively.

[![Development Status](https://github.com/socketry/falcon/workflows/Development/badge.svg)](https://github.com/socketry/falcon/actions?workflow=Development)

## Motivation

Initially, when I developed [async](https://github.com/socketry/async), I saw an opportunity to implement [async-http](https://github.com/socketry/async-http): providing both client and server components. After experimenting with these ideas, I decided to build an actual web server for comparing and validating performance primarily out of interest. Falcon grew out of those experiments and permitted the ability to test existing real-world code on top of [async](https://github.com/socketry/async).

Once I had something working, I saw an opportunity to simplify my development, testing and production environments, replacing production (Nginx+Passenger) and development (Puma) with Falcon. Not only does this simplify deployment, it helps minimize environment-specific bugs.

My long term vision for Falcon is to make a web application platform which trivializes server deployment. Ideally, a web application can fully describe all it's components: HTTP servers, databases, periodic jobs, background jobs, remote management, etc. Currently, it is not uncommon for all these facets to be handled independently in platform specific ways. This can make it difficult to set up new instances as well as make changes to underlying infrastructure. I hope Falcon can address some of these issues in a platform agnostic way.

As web development is something I'm passionate about, having a server like Falcon is empowering.

## Priority Business Support

Falcon can be an important part of your business or project, both improving performance and saving money. As such, priority business support is available to make every project a success. The support agreement will give you:

  - Direct support and assistance via Slack and email.
  - Advance notification of bugs and security issues.
  - Priority consideration of feature requests and bug reports.
  - Better software by funding development and testing.

Please visit [Socketry.io](https://socketry.io) to register and subscribe.

## Usage

Please see the <a href="https://socketry.github.io/falcon/">project documentation</a> or run it locally using `bake utopia:project:serve`.

## Contributing

We welcome contributions to this project.

1.  Fork it
2.  Create your feature branch (`git checkout -b my-new-feature`)
3.  Commit your changes (`git commit -am 'Add some feature'`)
4.  Push to the branch (`git push origin my-new-feature`)
5.  Create new Pull Request

### Responsible Disclosure

We take the security of our systems seriously, and we value input from the security community. The disclosure of security vulnerabilities helps us ensure the security and privacy of our users. If you believe you've found a security vulnerability in one of our products or platforms please [tell us via email](mailto:contact@oriontransfer.co.nz?subject=Falcon%20Security).

## Websites using Falcon

Websites below are listed in alphabetical order.

  - iCook - <https://icook.tw>
  - RubyAPI - <https://rubyapi.org>
  - YonderBook - <https://www.yonderbook.com/>

You're welcome to file a PR if you want to add your sites here.

## License

Released under the MIT license.

Copyright, 2018, by [Samuel G. D. Williams](http://www.codeotaku.com).

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
