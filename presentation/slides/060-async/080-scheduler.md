---
template: code
duration: 10
title: A Simplified Fiber Scheduler
transition: fade
---

```ruby
class Scheduler
  def io_wait(io, events, timeout)
    fiber = Fiber.current
    selector.io_wait(fiber, io, events)

    transfer
  end

  def run
    while fiber = selector.select
      fiber.transfer
    end
  end
end
```

---

Conceptually, the scheduler has two responsibilities: suspend fibers that must wait, and resume fibers that are ready.
