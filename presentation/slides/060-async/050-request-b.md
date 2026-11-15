---
template: code
duration: 12
focus: 7-10
title: Request B Runs While A Waits
---

```ruby
Async do |server|
  request_a = server.async do
    cart = Core.fetch_cart(session_a)
    send_response(200, render(cart))
  end

  request_b = server.async do
    products = Spanner.query_catalog(shop)
    send_response(200, render(products))
  end

  request_a.wait
  request_b.wait
end
```

---

The scheduler transfers control to Request B. Both requests remain in progress, but only one fiber executes at a time on this worker.
