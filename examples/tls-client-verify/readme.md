# TLS Client Verify

It is possible to verify inbound client requests using TLS client certificates. This is useful for ensuring that only authorized clients can access your service. In order to do this, you need to configure Falcon to use a TLS context with additional client verification options.

```ruby
	ssl_context do
		super().tap do |context|
			context.verify_mode = OpenSSL::SSL::VERIFY_PEER
			
			context.verify_callback = proc do |verified, store_context|
				# Add your custom verification logic here.
				true
			end
		end
	end
```

## Server

``` bash
$ bundle exec falcon host
```

### Client

``` bash
$ openssl s_client -connect localhost:9292 -cert client.crt -key client.key
```
