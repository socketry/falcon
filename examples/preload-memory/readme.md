# Preload Memory Example

This example demonstrates how preloaded memory is accounted for across forked processes.

It allocates memory before forking one supervisor-like process and several worker-like processes. The preloaded pages should be shared by copy-on-write until a child mutates them, but per-process RSS reports the full resident mapping for every process. Summing RSS therefore overstates the physical memory pressure of a forked process tree.

The example uses `process-metrics` to report:

- RSS (`resident_size`): resident pages visible from each process.
- PSS (`proportional_size`): each process's proportional share of shared pages, where available.
- Shared memory (`shared_clean_size + shared_dirty_size`).
- Private memory (`private_clean_size + private_dirty_size`).

## Usage

Run the example:

```bash
$ bundle exec ruby examples/preload-memory/shared_pages.rb
```

Adjust the scenario with environment variables:

```bash
$ PRELOAD_MB=512 WORKERS=3 PRIVATE_MB=64 bundle exec ruby examples/preload-memory/shared_pages.rb
```

`PRELOAD_MB` controls the memory allocated before forking. `WORKERS` controls the number of worker-like child processes. `PRIVATE_MB` optionally mutates part of the preloaded memory in each worker to demonstrate copy-on-write private growth.

On Linux, `process-metrics` can read `/proc/<pid>/smaps` and should report PSS and private/shared page counts. On platforms without detailed memory accounting, those fields may be missing or less accurate.
