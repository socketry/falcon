# Extended Features

This guide explains some of the extended features and functionality of Falcon.

## WebSockets

You can use [async-websocket] in any controller layer to serve WebSocket connections.

[async-websocket]: https://github.com/socketry/async-websocket

## Early Hints

Falcon supports the `rack.early_hints` API when running over HTTP/2. You can [read more about the implementation and proposed interface](https://www.codeotaku.com/journal/2019-02/falcon-early-hints/index).
