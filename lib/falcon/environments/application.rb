# frozen_string_literal: true

# Copyright, 2019, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

require_relative '../proxy_endpoint'
require_relative '../server'

require_relative '../service/application'

# A general application environment.
# Suitable for use with any {Protocol::HTTP::Middleware}.
#
# @scope Falcon Environments
# @name application
environment(:application) do
	# The middleware stack for the application.
	# @attr [Protocol::HTTP::Middleware]
	middleware do
		::Protocol::HTTP::Middleware::HelloWorld
	end
	
	# The scheme to use to communicate with the application.
	# @attr [String]
	scheme 'https'
	
	# The protocol to use to communicate with the application.
	#
	# Typically one of {Async::HTTP::Protocol::HTTP1} or {Async::HTTP::Protocl::HTTP2}.
	#
	# @attr [Async::HTTP::Protocol]
	protocol {Async::HTTP::Protocol::HTTP2}
	
	# The IPC path to use for communication with the application.
	# @attr [String]
	ipc_path {::File.expand_path("application.ipc", root)}
	
	# The endpoint that will be used for communicating with the application server.
	# @attr [Async::IO::Endpoint]
	endpoint do
		::Falcon::ProxyEndpoint.unix(ipc_path,
			protocol: protocol,
			scheme: scheme,
			authority: authority
		)
	end
	
	# The service class to use for the application.
	# @attr [Class]
	service ::Falcon::Service::Application
end