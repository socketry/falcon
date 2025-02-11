# Limited Example

This example shows how to limit the number of connections to a server. It takes advantage of `IO::Endpoint`'s wrapper to inject the necessary logic. More specifically, we do the following:

1. Instead of `accept`ing a connection in a loop directly, we call `server.wait_readable` to wait for a connection to be available.
2. We then try to acquire a semaphore token. If we can't, we wait for one to be available.
3. Once we have a token, we accept the connection and process it.
4. Once the connection is closed, we release the token.

This way, we can limit the number of connections to a server.

## Usage

Start the server:

```console
> bundle exec falcon host falcon.rb
  0.0s     info: Falcon::Command::Host [oid=0x4c8] [ec=0x4d0] [pid=99469] [2025-02-11 17:53:59 +1300]
               | Falcon Host v0.49.0 taking flight!
               | - Configuration: falcon.rb
               | - To terminate: Ctrl-C or kill 99469
               | - To reload: kill -HUP 99469
 0.03s     info: Async::Container::Notify::Console [oid=0x4d8] [ec=0x4d0] [pid=99469] [2025-02-11 17:53:59 +1300]
               | {status: "Initializing..."}
 0.04s     info: Falcon::Service::Server [oid=0x4e8] [ec=0x4d0] [pid=99469] [2025-02-11 17:53:59 +1300]
               | Starting limited.localhost on #<Async::HTTP::Endpoint http://localhost:8080/ {reuse_address: true, timeout: nil, wrapper: #<Limited::Wrapper:0x000000011f5dfc30>}>
 0.04s     info: Async::Service::Controller [oid=0x4f0] [ec=0x4d0] [pid=99469] [2025-02-11 17:53:59 +1300]
               | Controller starting...
 0.04s     info: Async::Container::Notify::Console [oid=0x4d8] [ec=0x4d0] [pid=99469] [2025-02-11 17:53:59 +1300]
               | {ready: true}
 0.04s     info: Async::Service::Controller [oid=0x4f0] [ec=0x4d0] [pid=99469] [2025-02-11 17:53:59 +1300]
               | Controller started...
```

Then, you can connect to it using `curl -v http://localhost:8080`. The default example includes two workers with a limit of one connection per worker.

```console
> curl -v http://localhost:8080
* Host localhost:8080 was resolved.
* IPv6: ::1
* IPv4: 127.0.0.1
*   Trying [::1]:8080...
* Connected to localhost (::1) port 8080
* using HTTP/1.x
> GET / HTTP/1.1
> Host: localhost:8080
> User-Agent: curl/8.10.1
> Accept: */*
> 
* Request completely sent off
< HTTP/1.1 200 OK
< vary: accept-encoding
< content-length: 11
< 
* Connection #0 to host localhost left intact
Hello World
```

There is also a fast path which simulates requests that may not count towards the connection limit:

```console
> curl -v http://localhost:8080/fast http://localhost:8080/fast
* Host localhost:8080 was resolved.
* IPv6: ::1
* IPv4: 127.0.0.1
*   Trying [::1]:8080...
* Connected to localhost (::1) port 8080
* using HTTP/1.x
> GET /fast HTTP/1.1
> Host: localhost:8080
> User-Agent: curl/8.10.1
> Accept: */*
> 
* Request completely sent off
< HTTP/1.1 200 OK
< vary: accept-encoding
< connection: close
< content-length: 11
< 
* shutting down connection #0
Hello World* Hostname localhost was found in DNS cache
*   Trying [::1]:8080...
* Connected to localhost (::1) port 8080
* using HTTP/1.x
> GET /fast HTTP/1.1
> Host: localhost:8080
> User-Agent: curl/8.10.1
> Accept: */*
> 
* Request completely sent off
< HTTP/1.1 200 OK
< vary: accept-encoding
< connection: close
< content-length: 11
< 
* shutting down connection #1
Hello World
```

Note that we use `connection: close` because we are using the fast path. This is to ensure that the connection is closed immediately after the response is sent such that a subsequent "slow" request won't double up.
