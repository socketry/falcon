# How It Works

This guide gives an overview of how Falcon handles an incoming web request.

## Overview

When you run `falcon serve`, Falcon creates a {ruby Falcon::Controller::Serve} which is used to create several worker threads or processes. Before starting the workers, the controller binds to an endpoint (e.g. a local unix socket, a TCP network socket, etc). The workers are spawned and receive this bound endpoint, and start accepting connections.

The workers individually load a copy of your rack application. These applications are wrapped using {ruby Falcon::Adapters::Rack} which modifies the incoming {ruby Protocol::HTTP::Request} object into an `env` object suitable for your application. It also handles converting the output of your rack application `[status, headers, body]` into an instance of {ruby Falcon::Adapters::Response} which is derived from {ruby Protocol::HTTP::Response}.

## Server

The server itself is mostly implemented by {ruby Async::HTTP::Server} which in turn depends on the `protocol-http` gems for the actual protocol implementations. Therefore, Falcon is primarily a bridge between the underlying protocol objects and the Rack interface.
