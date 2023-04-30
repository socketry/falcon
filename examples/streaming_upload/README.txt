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
Document Length:        42 bytes

Concurrency Level:      20
Time taken for tests:   132.450 seconds
Complete requests:      100
Failed requests:        0
Total transferred:      10400 bytes
Total body sent:        8254376202
HTML transferred:       4200 bytes
Requests per second:    0.76 [#/sec] (mean)
Time per request:       26490.033 [ms] (mean)
Time per request:       1324.502 [ms] (mean, across all concurrent requests)
Transfer rate:          0.08 [Kbytes/sec] received
                        60859.98 kb/s sent
                        60860.06 kb/s total

Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:        0    1   2.7      0      11
Processing:  1493 23921 5256.1  26331   30499
Waiting:      115  134  12.1    133     164
Total:       1493 23922 5255.3  26331   30499

Percentage of the requests served within a certain time (ms)
  50%  26331
  66%  26430
  75%  26593
  80%  26777
  90%  27262
  95%  29422
  98%  30418
  99%  30499
 100%  30499 (longest request)
```