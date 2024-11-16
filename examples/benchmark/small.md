## Puma

```
Thread Stats   Avg      Stdev     Max   +/- Stdev
	Latency     2.05ms  312.41us   5.88ms   80.73%
	Req/Sec     0.98k    41.36     1.05k    57.50%
3892 requests in 2.00s, 4.87MB read
Requests/sec:   1945.51
Transfer/sec:      2.43MB

% time     seconds  usecs/call     calls    errors syscall
------ ----------- ----------- --------- --------- ----------------
 88.23    0.690607           4    163975           write
  5.42    0.042420           5      7792           setsockopt
  2.20    0.017235           4      3898           recvfrom
  1.73    0.013570           3      3898           getsockopt
  1.53    0.011956           3      3896           getpeername
  0.88    0.006876           3      2056           read
  0.00    0.000026          13         2           listen
  0.00    0.000024           2         9           getsockname
  0.00    0.000007           7         1           socket
  0.00    0.000007           0         8         2 accept4
  0.00    0.000005           5         1           bind
------ ----------- ----------- --------- --------- ----------------
100.00    0.782733           4    185536         2 total
```

## Falcon

```
Thread Stats   Avg      Stdev     Max   +/- Stdev
	Latency    10.92ms   14.15ms  46.63ms   78.30%
	Req/Sec     1.02k   222.88     1.45k    65.00%
4059 requests in 2.00s, 4.80MB read
Requests/sec:   2026.72
Transfer/sec:      2.40MB

% time     seconds  usecs/call     calls    errors syscall
------ ----------- ----------- --------- --------- ----------------
 69.12    0.042774           5      8128           sendto
 20.04    0.012400           2      4242       174 recvfrom
  9.91    0.006133           2      2071         8 read
  0.47    0.000290          13        21           getsockname
  0.20    0.000126           6        20           getsockopt
  0.19    0.000115           5        20        14 accept4
  0.06    0.000035           2        14           write
  0.02    0.000014           2         7           setsockopt
  0.00    0.000000           0         1           socket
  0.00    0.000000           0         1           bind
  0.00    0.000000           0         1           listen
------ ----------- ----------- --------- --------- ----------------
100.00    0.061887           4     14526       196 total
```
