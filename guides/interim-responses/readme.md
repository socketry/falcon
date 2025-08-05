# Interim Responses

This guide explains how to use interim responses in Falcon to send early hints to the client.

## Overview

Interim responses allow the server to send early hints to the client before the final response is ready. This can be useful for preloading resources or providing immediate feedback. They can also be used as a response to the `expect` header, allowing the server to indicate that it is ready to process the request without waiting for the full request body.

Since Rack does not currently have a specificatio for interim responses, you need to access the underlying HTTP response object directly.

~~~ruby
# config.ru

run do |env|
	if request = env["protocol.http.request"]
		request.send_interim_response(103, [["link", "</style.css>; rel=preload; as=style"]])
	end
end
~~~
