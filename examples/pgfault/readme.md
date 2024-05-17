# Objective-C Segfault

On macOS, some usage of the Objective-C runtime can cause issues when forking. This is a known issue but is not specifically a bug in Falcon.

## Usage

### Run the server

```bash
bundle exec falcon host
```

It should start correctly with no errors.

Now, comment out the preload group:

``` ruby
# group :preload do
	gem 'rdkafka', '~> 0.21.0'
# end
```

If you run the server again, it will fail:

```
objc[9330]: +[__NSCFConstantString initialize] may have been in progress in another thread when fork() was called.
objc[9330]: +[__NSCFConstantString initialize] may have been in progress in another thread when fork() was called. We cannot safely call it or ignore it in the fork() child process. Crashing instead. Set a breakpoint on objc_initializeAfterForkError to debug.
 2.33s    error: Async::Container::Forked [oid=0xa00] [ec=0xc30] [pid=8967] [2025-04-27 11:15:58 +0900]
               | {
               |   "status": "pid 9330 SIGABRT (signal 6)"
               | }
```
