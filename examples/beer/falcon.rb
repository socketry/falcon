#!/usr/bin/env -S falcon host

host 'beer.localhost', :rack, :self_signed do
	root __dir__
end
