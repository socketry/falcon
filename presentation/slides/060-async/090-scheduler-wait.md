---
template: code
duration: 12
focus: 2-7
title: Suspend the Waiting Fiber
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

The scheduler registers the current fiber's interest in the I/O event, then transfers control back to the event loop.
