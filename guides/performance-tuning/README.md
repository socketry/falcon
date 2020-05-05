# Performance Tuning

This guide explains the performance characteristics of Falcon.

## Scalability

Falcon uses an asynchronous event-driven reactor to provide non-blocking IO. It uses one Fiber per request, which have minimal overhead. Falcon can handle a large number of in-flight requests including long-running connections like websockets, HTTP/2 streaming, etc.

- [Improving Ruby Concurrency](https://www.codeotaku.com/journal/2018-06/improving-ruby-concurrency/index#performance) – Comparison of Falcon and Puma.

### Falcon Benchmark

The [falcon-benchmark] suite looks at how various servers respond to different levels of concurrency across several sample applications.

[falcon-benchmark]: https://github.com/socketry/falcon-benchmark

## Memory Usage

Falcon uses [async-container] to start multiple copies of your application. Each instance of your application is isolated by default for maximum fault-tolerance. However, this can lead to increased memory usage. Preloading parts of your application reduce this overhead and in addition can improve instance start-up time. To understand your application memory usage, you should use [process-metrics] which take into account memory shared between processes.

[async-container]: https://github.com/socketry/async-container
[process-metrics]: https://github.com/socketry/process-metrics

### Preloading

Falcon offers two mechanisms for preloading code.

#### Preloading Gems

By default, falcon will load all gems in the `preload` group:

~~~ ruby
# In gems.rb:

source "https://rubygems.org"

group :preload do
	# List any gems you want to be pre-loaded into the falcon process before forking.
end
~~~

#### Preloading Files

Create a file in your application called `preload.rb`. You can put this file anywhere in your application.

##### Falcon Serve

`falcon serve` has a `--preload` option which accepts the path to this file.

##### Falcon Host

`falcon.rb` applications may have a `preload` configuration option.

## System Limitations

If you are expecting to handle many simultaneous connections, please ensure you configure your file limits correctly.

```
Errno::EMFILE: Too many open files - accept(2)
```

This means that your system is limiting the number of files that can be opened by falcon. Please check the `ulimit` of your system and set it appropriately.
