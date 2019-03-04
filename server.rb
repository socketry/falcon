#!/usr/bin/env -S ./bin/falcon virtual --bind-insecure http://[::]:1080 --bind-secure https://[::]:1443

rack 'localhost', :self_signed do
	root File.expand_path("examples/benchmark/", __dir__)
end
