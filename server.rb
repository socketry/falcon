#!/usr/bin/env -S falcon virtual --bind-insecure "http://[::]:1080" --bind-secure "http://[::]:1443"

rack 'localhost', :self_signed do
	root File.expand_path("examples/benchmark/", __dir__)
end
