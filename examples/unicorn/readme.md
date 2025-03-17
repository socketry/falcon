# Unicorn (Mode)

This is a comparison of Unicorn and Falcon running in single-request-per-process / `connection: close`.

## Unicorn

```sh
> bundle exec unicorn -E production --port 9090
```

## Falcon

```sh
> bundle exec falcon host falcon.rb
```

## Results

```
samuel@sakura ~/D/i/wrk (main)> ./wrk --verbose -t1 -c1 -d1 http://localhost:8080
Running 1s test @ http://localhost:8080
  1 threads and 1 connections
  6795 requests in 1.10s, 610.49KB read
Requests/sec:   6170.43
Transfer/sec:    554.37KB

Thread Stats         Avg       Stdev         Min         Max    +/- Stdev 
     Latency:     153.80us    227.98us     94.00us      5.12ms   97.91%
     Req/sec:       6.22k       2.15k      49.00        7.25k    90.91%
samuel@sakura ~/D/i/wrk (main)> ./wrk --verbose -t1 -c1 -d1 http://localhost:9090
Running 1s test @ http://localhost:9090
  1 threads and 1 connections
  12070 requests in 1.10s, 0.99MB read
Requests/sec:  10963.92
Transfer/sec:      0.90MB

Thread Stats         Avg       Stdev         Min         Max    +/- Stdev 
     Latency:     190.98us      1.06ms     45.00us     15.56ms   98.39%
     Req/sec:      11.03k       3.48k     712.00       12.68k    90.91%
```
