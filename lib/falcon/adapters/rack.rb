# Copyright, 2017, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'rack'

require_relative 'input'
require_relative 'response'
require_relative 'early_hints'

require 'async/logger'

module Falcon
	module Adapters
		class Rack
			# CGI keys (https://tools.ietf.org/html/rfc3875#section-4.1)
			HTTP_HOST = 'HTTP_HOST'.freeze
			PATH_INFO = 'PATH_INFO'.freeze
			REQUEST_METHOD = 'REQUEST_METHOD'.freeze
			REQUEST_PATH = 'REQUEST_PATH'.freeze
			REQUEST_URI = 'REQUEST_URI'.freeze
			SCRIPT_NAME = 'SCRIPT_NAME'.freeze
			QUERY_STRING = 'QUERY_STRING'.freeze
			SERVER_PROTOCOL = 'SERVER_PROTOCOL'.freeze
			SERVER_NAME = 'SERVER_NAME'.freeze
			SERVER_PORT = 'SERVER_PORT'.freeze
			REMOTE_ADDR = 'REMOTE_ADDR'.freeze
			CONTENT_TYPE = 'CONTENT_TYPE'.freeze
			CONTENT_LENGTH = 'CONTENT_LENGTH'.freeze
			
			# Rack environment variables
			RACK_VERSION = 'rack.version'.freeze
			RACK_ERRORS = 'rack.errors'.freeze
			RACK_LOGGER = 'rack.logger'.freeze
			RACK_INPUT = 'rack.input'.freeze
			RACK_MULTITHREAD = 'rack.multithread'.freeze
			RACK_MULTIPROCESS = 'rack.multiprocess'.freeze
			RACK_RUNONCE = 'rack.run_once'.freeze
			RACK_URL_SCHEME = 'rack.url_scheme'.freeze
			RACK_HIJACK = 'rack.hijack'.freeze
			RACK_IS_HIJACK = 'rack.hijack?'.freeze
			RACK_HIJACK_IO = 'rack.hijack_io'.freeze
			RACK_EARLY_HINTS = "rack.early_hints".freeze
			
			ASYNC_HTTP_REQUEST = "async.http.request".freeze
			
			# Header constants
			HTTP_X_FORWARDED_PROTO = 'HTTP_X_FORWARDED_PROTO'.freeze
			
			def initialize(app, logger = Async.logger)
				@app = app
				
				raise ArgumentError, "App must be callable!" unless @app.respond_to?(:call)
				
				@logger = logger
			end
			
			# Rack separates multiple headers with the same key, into a single field with multiple "lines".
			def unwrap_headers(headers, env)
				headers.each do |key, value|
					http_key = "HTTP_#{key.upcase.tr('-', '_')}"
					
					if current_value = env[http_key]
						env[http_key] = "#{current_value};#{value}"
					else
						env[http_key] = value
					end
				end
			end
			
			# Process the incoming request into a valid rack env.
			def unwrap_request(request, env)
				if content_type = request.headers.delete('content-type')
					env[CONTENT_TYPE] = content_type
				end
				
				# In some situations we don't know the content length, e.g. when using chunked encoding, or when decompressing the body.
				if body = request.body and length = body.length
					env[CONTENT_LENGTH] = length.to_s
				end
				
				self.unwrap_headers(request.headers, env)
				
				# HTTP/2 prefers `:authority` over `host`, so we do this for backwards compatibility.
				env[HTTP_HOST] ||= request.authority
				
				# This is the HTTP/1 header for the scheme of the request and is used by Rack.
				# Technically it should use the Forwarded header but this is not common yet.
				# https://tools.ietf.org/html/rfc7239#section-5.4
				# https://github.com/rack/rack/issues/1310
				env[HTTP_X_FORWARDED_PROTO] ||= request.scheme
				env[RACK_URL_SCHEME] = env[HTTP_X_FORWARDED_PROTO]
				
				if remote_address = request.remote_address
					env[REMOTE_ADDR] = remote_address.ip_address if remote_address.ip?
				end
			end
			
			def call(request)
				request_path, query_string = request.path.split('?', 2)
				server_name, server_port = (request.authority || '').split(':', 2)
				
				env = {
					RACK_VERSION => [2, 0, 0],
					
					ASYNC_HTTP_REQUEST => request,
					
					RACK_INPUT => Input.new(request.body),
					RACK_ERRORS => $stderr,
					RACK_LOGGER => Async.logger,
					
					RACK_MULTITHREAD => true,
					RACK_MULTIPROCESS => true,
					RACK_RUNONCE => false,
					
					# The HTTP request method, such as “GET” or “POST”. This cannot ever be an empty string, and so is always required.
					REQUEST_METHOD => request.method,
					
					# The initial portion of the request URL's “path” that corresponds to the application object, so that the application knows its virtual “location”. This may be an empty string, if the application corresponds to the “root” of the server.
					SCRIPT_NAME => '',
					
					# The remainder of the request URL's “path”, designating the virtual “location” of the request's target within the application. This may be an empty string, if the request URL targets the application root and does not have a trailing slash. This value may be percent-encoded when originating from a URL.
					PATH_INFO => request_path,
					REQUEST_PATH => request_path,
					REQUEST_URI => request.path,

					# The portion of the request URL that follows the ?, if any. May be empty, but is always required!
					QUERY_STRING => query_string || '',
					
					# The server protocol (e.g. HTTP/1.1):
					SERVER_PROTOCOL => request.version,
					
					# The request scheme:
					RACK_URL_SCHEME => request.scheme,
					
					# I'm not sure what sane defaults should be here:
					SERVER_NAME => server_name || '',
					SERVER_PORT => server_port || '',
					
					# We support both request and response hijack.
					RACK_IS_HIJACK => true,
				}
				
				self.unwrap_request(request, env)

				if request.push?
					env[RACK_EARLY_HINTS] = EarlyHints.new(request)
				end
				
				full_hijack = false
				
				if request.hijack?
					env[RACK_HIJACK] = lambda do
						wrapper = request.hijack!
						full_hijack = true
						
						# We dup this as it might be taken out of the normal control flow, and the io will be closed shortly after returning from this method.
						io = wrapper.io.dup
						wrapper.close
						
						# This is implicitly returned:
						env[RACK_HIJACK_IO] = io
					end
				end
				
				status, headers, body = @app.call(env)
				
				# If there was a full hijack:
				if full_hijack
					return nil
				else
					return Response.wrap(status, headers, body, request)
				end
			rescue => exception
				@logger.error(self) {exception}
				
				return failure_response(exception)
			end
			
			def failure_response(exception)
				Protocol::HTTP::Response.for_exception(exception)
			end
		end
	end
end
