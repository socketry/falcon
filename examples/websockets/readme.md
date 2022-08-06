# WebSockets Example

Shows a small demo of how to use WebSockets with Rack/Falcon.

## Usage

Install the dependencies:

```bash
$ bundle install
```

In one terminal, start the server:

```bash
$ bundle exec falcon serve
```

In another terminal, use a tool like `wscat` or `websocat`:

```bash
$ websocat wss://localhost:9292/
{"message":"Hello World"}
{"message":"Hello World"}
{"message":"Hello World"}
{"message":"Hello World"}
{"message":"Hello World"}
{"message":"Hello World"}
^C⏎
```
