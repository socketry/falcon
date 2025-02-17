# Pushback

The problem to solve is to have long running requests limited to a
certain number of concurrent request.

If more requests are comming in they are responded with code 429.

# Running it
```
bundle install
bundle exec falcon -n 1 --bind http://localhost:9292
```

in another console you can run an apache-ab test:

```
ab -c 17 -n 17  localhost:9292/1
```

