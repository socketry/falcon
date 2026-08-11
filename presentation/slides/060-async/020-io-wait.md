---
template: statement
duration: 18
marker: Async
transition: fade
---

Async turns I/O waits into suspension points.

---

Each task runs inside a fiber. When an operation would block on I/O, the fiber is suspended and the scheduler can run another ready task on the same worker.
