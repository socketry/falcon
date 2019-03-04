#!/usr/bin/env -S ./bin/falcon virtual --bind-insecure http://[::]:1080 --bind-secure https://[::]:1443

rack 'benchmark.localhost', :self_signed do
	root File.expand_path("examples/benchmark/", __dir__)
end

rack 'beer.localhost', :self_signed do
	root File.expand_path("examples/beer/", __dir__)
end

rack 'hello.localhost', :self_signed do
	root File.expand_path("examples/hello/", __dir__)
end
