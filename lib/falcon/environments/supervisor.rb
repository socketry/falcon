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

require_relative '../service/supervisor'

# A application process monitor environment.
#
# @scope Falcon Environments
# @name supervisor
environment(:supervisor) do
	# The name of the supervisor
	# @attribute [String]
	name "supervisor"
	
	# The IPC path to use for communication with the supervisor.
	# @attribute [String]
	ipc_path do
		::File.expand_path("supervisor.ipc", root)
	end
	
	# The endpoint the supervisor will bind to.
	# @attribute [Async::IO::Endpoint]
	endpoint do
		Async::IO::Endpoint.unix(ipc_path)
	end
	
	# The service class to use for the supervisor.
	# @attribute [Class]
	service do
		::Falcon::Service::Supervisor
	end
end
