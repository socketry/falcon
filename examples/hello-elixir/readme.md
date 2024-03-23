# Hello Elixir

This is a simple Elixir application for performance comparison.

## Usage

``` shell
# Install dependencies:
$ mix deps.get

# Run the application:
$ mix run --no-halt
```

You can then access the application at `http://localhost:3000`:

``` shell
$ curl -v http://localhost:3000
* Host localhost:3000 was resolved.
* IPv6: ::1
* IPv4: 127.0.0.1
*   Trying [::1]:3000...
* connect to ::1 port 3000 from ::1 port 54328 failed: Connection refused
*   Trying 127.0.0.1:3000...
* Connected to localhost (127.0.0.1) port 3000
> GET / HTTP/1.1
> Host: localhost:3000
> User-Agent: curl/8.6.0
> Accept: */*
> 
< HTTP/1.1 200 OK
< cache-control: max-age=0, private, must-revalidate
< content-length: 11
< content-type: text/plain; charset=utf-8
< date: Sat, 23 Mar 2024 04:00:53 GMT
< server: Cowboy
< 
* Connection #0 to host localhost left intact
Hello World
```
