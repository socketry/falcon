---
template: code
duration: 12
focus: 9-12
title: Resume Ready Fibers
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

The event loop waits for readiness and transfers control to fibers that can make progress. When they need to wait again, control returns to the loop.
