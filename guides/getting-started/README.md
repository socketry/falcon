# Getting Started

This guide explains how to use Falcon for Ruby web application development.

## Falcon Serve

You can run `falcon serve` directly. It will load the `config.ru` and start serving on <a href="https://localhost:9292">https://localhost:9292</a>.

To run on a different port:

~~~ bash
$ falcon serve --port 3000
~~~

### Integration with Guard

Falcon can restart very quickly and is ideal for use with guard. See [guard-falcon] for more details.

[guard-falcon]: https://github.com/socketry/guard-falcon

### Integration with Capybara

Falcon can run in the same process on a different thread, so it's great for use with Capybara (and shared ActiveRecord transactions). See [falcon-capybara] for more details.

[falcon-capybara]: https://github.com/socketry/falcon-capybara

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