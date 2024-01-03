# Streaming Upload

# ab Results

The filesize was 82078050 bytes.

## concurrent requests

```
> bundle exec falcon host ./falcon.rb
```

```
> dd if=/dev/zero of=./testfile bs=82078050 count=1
> time ab -n 1000 -c 32 -p ./testfile -H "Expect: 100-continue" http://localhost:9292/
This is ApacheBench, Version 2.3 <$Revision: 1903618 $>
Copyright 1996 Adam Twiss, Zeus Technology Ltd, http://www.zeustech.net/
Licensed to The Apache Software Foundation, http://www.apache.org/

Benchmarking localhost (be patient)
Completed 100 requests
Completed 200 requests
Completed 300 requests
Completed 400 requests
Completed 500 requests
Completed 600 requests
Completed 700 requests
Completed 800 requests
Completed 900 requests
Completed 1000 requests
Finished 1000 requests


Server Software:        
Server Hostname:        localhost
Server Port:            9292

Document Path:          /
Document Length:        163 bytes

Concurrency Level:      32
Time taken for tests:   23.320 seconds
Complete requests:      1000
Failed requests:        94
   (Connect: 0, Receive: 0, Length: 94, Exceptions: 0)
Non-2xx responses:      25
Total transferred:      180172 bytes
Total body sent:        83232690408
HTML transferred:       162798 bytes
Requests per second:    42.88 [#/sec] (mean)
Time per request:       746.253 [ms] (mean)
Time per request:       23.320 [ms] (mean, across all concurrent requests)
Transfer rate:          7.54 [Kbytes/sec] received
                        3485442.37 kb/s sent
                        3485449.92 kb/s total

Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:        0   43   8.1     44      61
Processing:   185  690  93.6    679    1064
Waiting:        0   43   6.4     44      59
Total:        185  733  93.6    723    1081

Percentage of the requests served within a certain time (ms)
  50%    723
  66%    759
  75%    787
  80%    806
  90%    853
  95%    907
  98%    963
  99%    989
 100%   1081 (longest request)

________________________________________________________
Executed in   23.36 secs    fish           external
   usr time    0.07 secs  242.00 micros    0.07 secs
   sys time   20.28 secs  104.00 micros   20.28 secs

```

EOFError errors cause the failed uploads....have to figure out why.
