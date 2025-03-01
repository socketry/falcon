# Benchmark Example

## Usage

First, ensure you have `k6` installed. Then, start the server:

```bash
$ falcon serve --bind http://localhost:9292
```

Then run `k6`:

```bash
$ k6 run small.js
```
## Comparison

You could start the included `config.ru` with other servers and compare.
