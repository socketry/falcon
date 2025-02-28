# Supervisor Example

This example demonstrates how to use the supervisor to detect memory leaks and respond to them.

## `falcon.rb` Configuration

The `falcon.rb` configuration file is used to configure the Falcon web server, along with the supervisor. We have a custom `MemoryMonitor` so we can override some of the behaviour when a memory leak is detected.

## Usage

First, start the Falcon web server with the supervisor:

```bash
$ bundle exec falcon host falcon.rb
```

Then, cause a server instance to leak memory:

```bash
$ bake leak
```

The supervisor will detect the memory leak and restart the server instance:

```
50.17s    error: Falcon::Configuration::Loader["falcon.rb"]::MemoryMonitor [oid=0x548] [ec=0x550] [pid=91808] [2025-03-01 12:43:04 +1300]
               | Memory leak detected in process:
               | {
               |   "process_id": 91805,
               |   "monitor": {
               |     "process_id": 91805,
               |     "current_size": 27279360,
               |     "maximum_size": null,
               |     "maximum_size_limit": 20971520,
               |     "threshold_size": 10485760,
               |     "increase_count": 0,
               |     "increase_limit": 20
               |   }
               | }
50.27s     info: Falcon::Configuration::Loader["falcon.rb"]::MemoryMonitor [oid=0x548] [ec=0x550] [pid=91808] [2025-03-01 12:43:04 +1300]
               | Memory dumped...
               | {
               |   "response": {
               |     "path": "memory-91805.json"
               |   }
               | }
50.27s     info: Falcon::Configuration::Loader["falcon.rb"]::MemoryMonitor [oid=0x548] [ec=0x550] [pid=91808] [2025-03-01 12:43:04 +1300]
               | Killing process:
               | {
               |   "process_id": 91805
               | }
```
