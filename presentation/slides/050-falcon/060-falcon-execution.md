---
template: statement
duration: 20
marker: Falcon
transition: fade
---

Workers provide **parallelism.** Fibers provide **concurrency.**

---

Falcon combines both execution strategies: multiple workers can execute simultaneously, while each worker interleaves many requests efficiently.

The next question is how Async makes that interleaving possible without turning application code into callbacks.
