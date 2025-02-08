# Releases

## Unreleased

### Health Checks

Falcon adds support for the `Async::Container` health check which detects hung processes and restarts them. The default health check interval is 30 seconds.

`falcon serve` introduces a new `--health-check-timeout` option to configure the health check timeout. `falcon.rb`/`falcon host` can be changed using the `health_check_timeout` key within the `container_options` configuration - these are passed directly to `Async::Container`. If you don't want a health check, set `health_check_timeout` to `nil`.

### Falcon Server Process Title

The Falcon server process title is now updated periodically (alongside the health check) to include information about the numnber of connections and requests.

```
12211 ttys002    0:00.28 /Users/samuel/.gem/ruby/3.4.1/bin/falcon serve --bind http://localhost:8000      
12213 ttys002    0:04.14 http://localhost:8000 (C=2/2 R=0/49.45K L=0.353)
12214 ttys002    0:07.22 http://localhost:8000 (C=5/6 R=0/112.97K L=0.534)
12215 ttys002    0:05.41 http://localhost:8000 (C=3/3 R=0/71.7K L=0.439)
12216 ttys002    0:06.46 http://localhost:8000 (C=4/5 R=0/93.22K L=0.493)
12217 ttys002    0:02.58 http://localhost:8000 (C=1/1 R=0/24.9K L=0.251)
12218 ttys002    0:05.44 http://localhost:8000 (C=3/3 R=0/72.12K L=0.439)
12219 ttys002    0:06.47 http://localhost:8000 (C=4/4 R=0/93.13K L=0.493)
12220 ttys002    0:04.03 http://localhost:8000 (C=2/2 R=0/47.37K L=0.357)
12221 ttys002    0:06.41 http://localhost:8000 (C=4/4 R=0/92.46K L=0.494)
12222 ttys002    0:06.38 http://localhost:8000 (C=4/4 R=0/91.71K L=0.495)
```

- **C** – Connections: `(current/total)` connections accepted by the server  
- **R** – Requests: `(current/total)` requests processed by the server  
- **L** – Scheduler Load: A floating-point value representing the event loop load  

## v0.48.4

  - Improve compatibility of rackup handler w.r.t. sinatra.

## v0.47.8

  - Fix Falcon Supervisor implementation: due to invalid code, it was unable to start.
