# Streaming Upload

# ab Results

The filesize was 82078050 bytes.




## concurrent requests

```
bundle exec falcon host ./falcon.rb
```


```
This is ApacheBench, Version 2.3 <$Revision: 1879490 $>
Copyright 1996 Adam Twiss, Zeus Technology Ltd, http://www.zeustech.net/
Licensed to The Apache Software Foundation, http://www.apache.org/

Benchmarking localhost (be patient).....done


Server Software:        
Server Hostname:        localhost
Server Port:            9292

Document Path:          /
Document Length:        100 bytes

Concurrency Level:      20
Time taken for tests:   7.873 seconds
Complete requests:      100
Failed requests:        9
   (Connect: 0, Receive: 0, Length: 9, Exceptions: 0)
Total transferred:      16280 bytes
Total body sent:        8628660682
HTML transferred:       9989 bytes
Requests per second:    12.70 [#/sec] (mean)
Time per request:       1574.576 [ms] (mean)
Time per request:       78.729 [ms] (mean, across all concurrent requests)
Transfer rate:          2.02 [Kbytes/sec] received
                        1070310.40 kb/s sent
                        1070312.42 kb/s total

Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:        0   56  44.6     52     141
Processing:   296 1384 725.4   1159    4456
Waiting:       33  126  89.2    121     886
Total:        297 1440 720.8   1236    4464

Percentage of the requests served within a certain time (ms)
  50%   1236
  66%   1458
  75%   1627
  80%   1711
  90%   2020
  95%   3883
  98%   4463
  99%   4464
 100%   4464 (longest request)
```

EOFError errors cause the failed uploads....have to figure out why.
