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

load :application

# A rack application environment.
#
# Derived from {.application}.
#
# @scope Falcon Environments
# @name rack
environment(:rack, :application) do
	# The rack configuration path.
	# @attribute [String]
	config_path {::File.expand_path("config.ru", root)}
	
	# Whether to enable the application layer cache.
	# @attribute [String]
	cache false
	
	# The middleware stack for the rack application.
	# @attribute [Protocol::HTTP::Middleware]
	middleware do
		app, _ = ::Rack::Builder.parse_file(config_path)
		
		::Falcon::Server.middleware(app,
			verbose: verbose,
			cache: cache
		)
	end
end
