---
template: statement
duration: 20
marker: Throughput
transition: fade
---

So… how do we handle more requests?

---

Making Ruby ten times faster only reduced total latency from 100 milliseconds to 91 milliseconds—roughly a 1.1× speedup.

If most of each request is spent waiting, how can we use that waiting time to increase throughput?
