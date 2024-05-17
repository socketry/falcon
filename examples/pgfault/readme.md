# PG Segfault

On macOS, some usage of the Objective-C runtime can cause issues when forking. This can lead to a segmentation fault when using the `pg` gem with Falcon, but I've not been able to reproduce it thus far. If you encounter this, please report it: <https://github.com/socketry/falcon/issues/225>.

## Usage

### Postgres Setup

- Create a data directory.
- `initdb -D data/`
- `pg_ctl -D data/ start`
- `createdb test`

(To stop, run `pg_ctl -D data/ stop`.)

### Run the server

```bash
bundle exec falcon host
```

Then visit <http://hello.localhost:9292>, e.g.

```bash
curl http://hello.localhost:9292
```

You should see "Hello, World!" in the response (and no errors/segfaults in the server logs).
