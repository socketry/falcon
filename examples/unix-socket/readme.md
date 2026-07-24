# Unix Socket Example

This example demonstrates how to run a Falcon server using Unix domain sockets for communication instead of TCP sockets. Unix sockets provide faster inter-process communication when both client and server are on the same machine, with lower latency and higher throughput compared to TCP sockets.

## Overview

The example includes:
- A Falcon server that listens on a Unix socket at `/tmp/falcon-unix-socket-example.sock`
- Two HTTP endpoints: `/ping` (GET) and `/reverse` (POST)
- A Ruby client that demonstrates both endpoints with interactive messaging

## Usage

### 1. Start the Server

Run the Falcon server using the Unix socket configuration:

```bash
$ bundle exec falcon host falcon.rb
```

The server will create a Unix socket at `/tmp/falcon-unix-socket-example.sock` and listen for connections.

### 2. Run the Client

In a separate terminal, run the client:

```bash
$ ruby client.rb
```

The client will:
1. Send a ping request to test connectivity
2. Prompt you to enter messages that will be reversed by the server
3. Display the server responses

### 3. Example Session

```
🚀 Starting client...
🏓 Sending PING request...

Response: HTTP/1.1 200 OK
Connection: close
Content-Length: 4

PONG

Enter a message to reverse (or 'exit' to quit): Hello Falcon!

Response: HTTP/1.1 200 OK
Connection: close
Content-Length: 13

!noclaF olleH

Enter a message to reverse (or 'exit' to quit): exit
👋 Exiting client...
```

## API Endpoints

### GET `/ping`
- **Description**: Health check endpoint
- **Response**: Returns "PONG" with 200 status
- **Example**: `curl --unix-socket /tmp/falcon-unix-socket-example.sock http://localhost/ping`

### POST `/reverse`
- **Description**: Reverses the request body content
- **Request Body**: Any text content
- **Response**: The reversed text
- **Example**: `curl --unix-socket /tmp/falcon-unix-socket-example.sock -X POST -d "Hello" http://localhost/reverse`
