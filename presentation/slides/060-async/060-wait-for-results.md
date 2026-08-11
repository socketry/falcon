---
template: code
duration: 12
focus: 12-13
title: Wait for Both Requests
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

The parent task waits for both child tasks to finish. While either request is waiting on I/O, other ready tasks can continue to execute.
