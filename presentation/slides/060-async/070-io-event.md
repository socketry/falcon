---
template: statement
duration: 15
marker: Event Loop
transition: fade
---

`io-event` waits for readiness. Async decides what runs next.

---

The `io-event` selector integrates with the operating system to wait efficiently for I/O events. The Async scheduler resumes the fibers whose operations are ready to continue.
