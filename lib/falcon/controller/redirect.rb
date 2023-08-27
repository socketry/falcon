# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2023, by Samuel Williams.

require 'async/container/controller'

require_relative 'serve'
require_relative '../middleware/redirect'
require_relative '../service/proxy'

module Falcon
	module Controller
		# A controller for redirecting requests.
		class Redirect < Serve
			# Initialize the redirect controller.
			# @parameter command [Command::Redirect] The user-specified command-line options.
			def initialize(command, **options)
				super(command, **options)
				
				@hosts = {}
			end
			
			# Load the {Middleware::Redirect} application with the specified hosts.
			def load_app
				return Middleware::Redirect.new(Middleware::NotFound, @hosts, @command.redirect_endpoint)
			end
			
			# The name of the controller which is used for the process title.
			def name
				"Falcon Redirect Server"
			end
			
			# The endpoint the server will bind to.
			def endpoint
				@command.endpoint.with(
					reuse_address: true,
				)
			end
			
			# Builds a map of host redirections.
			def start
				configuration = @command.configuration
				
				services = Services.new(configuration)
				
				@hosts = {}
				
				services.each do |service|
					if service.is_a?(Service::Proxy)
						@hosts[service.authority] = service
					end
				end
				
				super
			end
		end
	end
end
