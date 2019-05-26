For every `falcon.rb`:

Spawn a child which loads falcon.rb:
	- Bind to `server.ipc`

Server loads falcon.rb:
	- Figure out whether it is application or not.

Server forks client:
	- Client binds to `server.ipc`.
	- Server connects to `server.ipc`.


Server expects client to bind to `server.ipc`.