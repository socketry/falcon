# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2025, by Samuel Williams.

require_relative "serve"
require_relative "host"
require_relative "virtual"
require_relative "proxy"
require_relative "redirect"
require_relative "static"

require_relative "../version"

require "samovar"

module Falcon
	module Command
		# The top level command for the `falcon` executable.
		class Top < Samovar::Command
			self.description = "An asynchronous HTTP server."
			
			# The command line options.
			# @attribute [Samovar::Options]
			options do
				option "--verbose | --quiet", "Verbosity of output for debugging.", key: :logging
				option "-h/--help", "Print out help information."
				option "-v/--version", "Print out the application version."
				option "-e/--encoding", "Specify the default external encoding of the server.", default: "UTF-8"
			end
			
			# The nested command to execute.
			# @name nested
			# @attribute [Command]
			nested :command, {
				"serve" => Serve,
				"host" => Host,
				"virtual" => Virtual,
				"proxy" => Proxy,
				"redirect" => Redirect,
				"static" => Static,
			}, default: "serve"
			
			# Whether verbose logging is enabled.
			# @returns [Boolean]
			def verbose?
				@options[:logging] == :verbose
			end
			
			# Whether quiet logging was enabled.
			# @returns [Boolean]
			def quiet?
				@options[:logging] == :quiet
			end
			
			# Update the external encoding.
			#
			# If you don't specify these, it's possible to have issues when encodings mismatch on the server.
			#
			# @parameter encoding [Encoding] Defaults to `Encoding::UTF_8`.
			def update_external_encoding!(encoding = Encoding::UTF_8)
				if Encoding.default_external != encoding
					Console.logger.warn(self) {"Updating Encoding.default_external from #{Encoding.default_external} to #{encoding}"}
					Encoding.default_external = encoding
				end
			end
			
			# The desired external encoding.
			def encoding
				if name = @options[:encoding]
					Encoding.find(name)
				end
			end
			
			# Prepare the environment and invoke the sub-command.
			def call
				if encoding = self.encoding
					update_external_encoding!(encoding)
				else
					update_external_encoding!
				end
				
				if @options[:version]
					puts "#{self.name} v#{Falcon::VERSION}"
				elsif @options[:help]
					self.print_usage
				else
					@command.call
				end
			end
		end
	end
end
