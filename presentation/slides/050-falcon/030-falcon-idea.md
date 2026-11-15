---
template: statement
duration: 15
marker: The Idea
transition: fade
---

When one request waits on I/O, let the worker run another request.

---

Database queries and network calls can take far longer than Ruby processing. Falcon uses that waiting time to make progress on other requests.
