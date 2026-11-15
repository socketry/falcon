---
template: code
duration: 12
focus: 2-5
title: Request A Runs Until It Waits
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

Request A runs normally until the cart fetch must wait for the network. Its fiber is suspended, leaving the worker free to run another task.
