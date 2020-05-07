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

require_relative '../services'

require 'async/container/controller'

module Falcon
	module Controller
		# A generic controller for serving an application.
		# Hosts several {Services} based on the command configuration.
		#
		# The configuration is provided by {Command::Host} and is typically loaded from a `falcon.rb` file. See {Configuration#load_file} for more details.
		class Host < Async::Container::Controller
			# Initialize the virtual controller.
			# @parameter command [Command::Host] The user-specified command-line options.
			def initialize(command, **options)
				@command = command
				
				@configuration = command.configuration
				@services = Services.new(@configuration)
				
				super(**options)
			end
			
			# Create the controller as specified by the command.
			# e.g. `Async::Container::Forked`.
			def create_container
				@command.container_class.new
			end
			
			# Start all specified services.
			def start
				@services.start
				
				super
			end
			
			# Setup all specified services into the container.
			# @parameter container [Async::Container::Generic]
			def setup(container)
				@services.setup(container)
			end
			
			# Stop all specified services.
			def stop(*)
				@services.stop
				
				super
			end
		end
	end
end
