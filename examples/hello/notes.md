Running the server:

```
samuel@Sakura ~/D/s/f/e/hello (main)> bundle exec falcon serve --bind http://[::]:9292 --count 1
  0.0s     info: Falcon::Command::Serve [oid=0x5d0] [ec=0x5d8] [pid=62134] [2026-03-19 17:54:58 +1300]
               | Falcon v0.55.2 taking flight! Using Async::Container::Forked {count: 1, restart: true, health_check_timeout: 30.0}.
               | - Running on ruby 3.4.8 (2025-12-17 revision 995b59f666) +PRISM [arm64-darwin25]
               | - Binding to: #<Falcon::Endpoint http://[::]:9292/ {}>
               | - To terminate: Ctrl-C or kill 62134
               | - To reload configuration: kill -HUP 62134
  0.0s     info: Async::Container::Notify::Console [oid=0x5e0] [ec=0x5d8] [pid=62134] [2026-03-19 17:54:58 +1300]
               | {status: "Initializing controller..."}
  0.0s     info: Falcon::Service::Server [oid=0x5f0] [ec=0x5d8] [pid=62134] [2026-03-19 17:54:58 +1300]
               | Starting http://[::]:9292 on #<Falcon::Endpoint http://[::]:9292/ {}>
  0.0s     info: Async::Service::Controller [oid=0x5f8] [ec=0x5d8] [pid=62134] [2026-03-19 17:54:58 +1300]
               | Controller starting...
  0.0s     info: Async::Service::Controller [oid=0x5f8] [ec=0x5d8] [pid=62134] [2026-03-19 17:54:58 +1300]
               | Starting container...
 0.01s     info: Async::Service::Controller [oid=0x5f8] [ec=0x5d8] [pid=62134] [2026-03-19 17:54:58 +1300]
               | Waiting for startup...
 0.01s     info: Async::Service::Controller [oid=0x5f8] [ec=0x5d8] [pid=62134] [2026-03-19 17:54:58 +1300]
               | Finished startup.
 0.01s     info: Async::Container::Notify::Console [oid=0x5e0] [ec=0x5d8] [pid=62134] [2026-03-19 17:54:58 +1300]
               | {ready: true, size: 1, status: "Running with 1 children."}
 0.01s     info: Async::Service::Controller [oid=0x5f8] [ec=0x5d8] [pid=62134] [2026-03-19 17:54:58 +1300]
               | Controller started.
```

Sending requests (in another terminal):

```
samuel@Sakura ~> curl http://localhost:9292
Fiber count: 9
samuel@Sakura ~> curl http://localhost:9292
Fiber count: 10
samuel@Sakura ~> curl http://localhost:9292
Fiber count: 11
samuel@Sakura ~> curl http://localhost:9292
Fiber count: 12
samuel@Sakura ~> curl http://localhost:9292
Fiber count: 13
samuel@Sakura ~> curl http://localhost:9292/gc
Fiber count: 8
samuel@Sakura ~> curl http://localhost:9292
Fiber count: 9
samuel@Sakura ~> curl http://localhost:9292
Fiber count: 10
```

## Why Fibers Accumulate (CRuby GC Analysis)

### Fibers are Write-Barrier Unprotected

In `cont.c`, `rb_fiber_data_type` is defined without `RUBY_TYPED_WB_PROTECTED`:

```c
static const rb_data_type_t rb_fiber_data_type = {
    "fiber",
    {fiber_mark, fiber_free, fiber_memsize, fiber_compact, fiber_handle_weak_references},
    0, 0, RUBY_TYPED_FREE_IMMEDIATELY  // ← no RUBY_TYPED_WB_PROTECTED
};
```

This makes every `Fiber` object **write-barrier unprotected** ("shady" in RGenGC terminology).

**Why they must be WB-unprotected:** `fiber_mark` → `cont_mark` → `rb_execution_context_mark` → `rb_gc_mark_machine_context`, which does a **conservative scan** of the fiber's native C machine stack. Any word that looks like a valid heap pointer is treated as an object reference. Since C-level pointers appear and disappear from the stack without any Ruby-level write operation, write barriers simply cannot track these changes.

### Fibers Never Age

In `gc/default/default.c`, `gc_aging` is called whenever an object is first marked. For WB-unprotected objects it does nothing:

```c
static void gc_aging(rb_objspace_t *objspace, VALUE obj) {
    ...
    if (!RVALUE_PAGE_WB_UNPROTECTED(page, obj)) {
        // increment age, promote to old at RVALUE_OLD_AGE (== 3)
        RVALUE_AGE_INC(objspace, obj);
    }
    // WB-unprotected objects: skip entirely — age stays at 0 forever
}
```

The GC consistency checker enforces this invariant:

```c
if (age > 0 && wb_unprotected_bit) {
    rb_bug("not WB protected, but age is %d > 0", age);
}
```

So fibers are **permanently young** (age 0). They never accumulate in `uncollectible_bits` (the old-generation bitmap) through the normal aging path.

### Minor GC vs. Major GC

At the start of each **minor GC** (`gc_marks_start`, `full_mark = false`):

```c
// Pre-mark all old (uncollectible) objects as alive
memcpy(&page->mark_bits[0], &page->uncollectible_bits[0], HEAP_PAGE_BITMAP_SIZE);

// Scan remembered set: old objects that recently wrote a reference to a young object
rgengc_rememberset_mark(objspace, heap);

// Then mark from actual GC roots
mark_roots(objspace, NULL);
```

Because fibers have `uncollectible_bits == 0`, they are **not pre-marked**. They survive a minor GC only if something marks them during the traversal — either via the remembered set or via reachability from GC roots (e.g., the current thread's stack or `th->scheduler`).

At the start of each **major GC** (`gc_marks_start`, `full_mark = true`):

```c
// Clear EVERYTHING — mark, uncollectible, marking, remembered bits
rgengc_mark_and_rememberset_clear(objspace, heap);
// Reset object counts
objspace->rgengc.old_objects = 0;
objspace->rgengc.uncollectible_wb_unprotected_objects = 0;
objspace->marked_slots = 0;
// Then do a full traversal from roots
mark_roots(objspace, NULL);
```

Every object must prove liveness from scratch.

### Why Completed Request Fibers Survive Minor GC

In a minor GC, old objects (like the long-lived `Async::Reactor`) start with their mark bit already set (pre-marked via `uncollectible_bits`). `gc_mark_set` returns immediately if the mark bit is already set:

```c
static inline int gc_mark_set(rb_objspace_t *objspace, VALUE obj) {
    if (RVALUE_MARKED(objspace, obj)) return 0; // already marked — don't re-scan
    ...
}
```

Pre-marked old objects are **not added to the grey queue** and **not re-scanned** in a minor GC. Their children are only traced if the old object is in the **remembered set** (`remembered_bits`), which is populated when a write barrier fires because the object stored a reference to a young object.

The remembered bit is **cleared** after each scan:

```c
bits[j] = remembered_bits[j] | (uncollectible_bits[j] & wb_unprotected_bits[j]);
remembered_bits[j] = 0; // cleared after use
```

So once a write barrier fires (e.g., when a task fiber is first stored in the reactor's data structure) and the next minor GC consumes it, the reactor is no longer in the remembered set. After that, the fiber survives subsequent minor GCs only if the reactor modifies its internal structures again (triggering a new write barrier) or if the fiber is reachable via some other path.

In practice, the Async reactor and scheduler **keep completed task fibers referenced** (e.g., in `@children` sets on `Async::Node`, via `Async::Task#fiber`). Because the reactor is an old object that is frequently mutated (new tasks arrive, timers fire, I/O events arrive), write barriers keep firing, continuously refreshing the remembered set for the reactor's containers. This keeps all referenced task fibers alive through every minor GC — they behave as if they are in the old generation, even though they never age past 0.

### Why `GC.start` (Major GC) Frees Them

During a major GC, `rgengc_mark_and_rememberset_clear` resets all bits to zero. The reactor starts with mark bit = 0. When `mark_roots` marks it, it becomes grey and is added to the mark stack. Only then are its **current** children traversed.

If Async has already cleaned up a completed task (removed it from `@children`, dropped the reference), that task's fiber is not reachable and gets swept. If the task is still held (e.g., awaiting `.wait`), the fiber survives.

### Summary

| Aspect | Behaviour |
|---|---|
| WB-unprotected? | Yes — conservative machine stack scan requires it |
| Ages to old? | Never — `gc_aging` skips WB-unprotected objects; age stays at 0 |
| `uncollectible_bits` set? | Not by normal aging; only via `gc_remember_unprotected` (not triggered for fresh fibers) |
| Survives minor GC? | Yes, if held by an old object that continuously re-enters the remembered set |
| Freed by minor GC? | Only if truly unreachable after the last write barrier for the holding container is consumed |
| Freed by `GC.start`? | Yes — full re-scan from roots discovers only currently-referenced objects |

The fiber count keeps climbing because the reactor is mutated frequently enough that its remembered bits are continuously refreshed, keeping every referenced task fiber alive through every minor GC. Only a major GC, which re-discovers the live set from scratch, can free fibers whose references have already been dropped.