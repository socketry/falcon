---
template: statement
duration: 20
marker: Async
transition: fade
---

Concurrency is transparent to the application code—no changes to existing application logic required.

---

Falcon and Ruby's fiber scheduler coordinate I/O waits beneath the Rack application. Existing request-handling logic can retain its ordinary sequential control flow.
