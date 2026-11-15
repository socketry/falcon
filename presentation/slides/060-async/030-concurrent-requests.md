---
template: code
duration: 12
title: Two Concurrent Requests
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

Each request is represented by an Async task. Within each task, the code remains sequential.
