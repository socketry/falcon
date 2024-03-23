# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024, by Samuel Williams.

require 'async/service/generic'

module Falcon
	module Service
		# A controller which mananages several virtual hosts.
		# Spawns instances of {Proxy} and {Redirect} to handle incoming requests.
		#
		# A virtual host is an application bound to a specific authority (essentially a hostname). The virtual controller manages multiple hosts and allows a single server to host multiple applications easily.
		class Virtual < Async::Service::Generic
			module Environment
				# The service class to use for the virtual host.
				# @returns [Class]
				def service_class
					Virtual
				end
				
				def name
					service_class.name
				end
				
				# All the falcon application configuration paths.
				# @returns [Array(String)] Paths to the falcon application configuration files.
				def configuration_paths
					["/srv/http/*/falcon.rb"]
				end
				
				def configuration
					::Async::Service::Configuration.load(configuration_paths)
				end
				
				# The URI to bind the `HTTPS` -> `falcon host` proxy.
				def bind_secure
					"https://[::]:443"
				end
				
				# The URI to bind the `HTTP` -> `HTTPS` redirector.
				def bind_insecure
					"http://[::]:80"
				end
				
				# The connection timeout to use for incoming connections.
				def timeout
					10.0
				end
				
				# # The insecure endpoint for connecting to the {Redirect} instance.
				# def insecure_endpoint(**options)
				# 	Async::HTTP::Endpoint.parse(bind_insecure, **options)
				# end
				
				# # The secure endpoint for connecting to the {Proxy} instance.
				# def secure_endpoint(**options)
				# 	Async::HTTP::Endpoint.parse(bind_secure, **options)
				# end
				
				# # An endpoint suitable for connecting to the specified hostname.
				# def host_endpoint(hostname, **options)
				# 	endpoint = secure_endpoint(**options)
					
				# 	url = URI.parse(bind_secure)
				# 	url.hostname = hostname
					
				# 	return Async::HTTP::Endpoint.new(url, hostname: endpoint.hostname)
				# end
			end
			
			def self.included(target)
				target.include(Environnment)
			end
			
			# Drop privileges according to the user and group of the specified path.
			# @parameter path [String] The path to the application directory.
			def assume_privileges(path)
				stat = File.stat(path)
				
				Process::GID.change_privilege(stat.gid)
				Process::UID.change_privilege(stat.uid)
				
				home = Etc.getpwuid(stat.uid).dir
				
				return {
					'HOME' => home,
				}
			end
			
			# Spawn an application instance from the specified path.
			# @parameter path [String] The path to the application directory.
			# @parameter container [Async::Container::Generic] The container to spawn into.
			# @parameter options [Options] The options which are passed to `exec`.
			def spawn(path, container, **options)
				container.spawn(name: "Falcon Application", restart: true, key: path) do |instance|
					env = assume_privileges(path)
					
					instance.exec(env,
						"bundle", "exec", "--keep-file-descriptors",
						path, ready: false, **options)
				end
			end
			
			# The path to the falcon executable from this gem.
			# @returns [String]
			def falcon_path
				File.expand_path("../../../bin/falcon", __dir__)
			end
			
			# Setup the container with {Redirect} and {Proxy} child processes.
			# These processes are gracefully restarted if they are already running.
			# @parameter container [Async::Container::Generic]
			def setup(container)
				if proxy = container[:proxy]
					proxy.kill(:HUP)
				end
				
				if redirect = container[:redirect]
					redirect.kill(:HUP)
				end
				
				container.reload do
					evaluator = @environment.evaluator
					
					evaluator.configuration_paths.each do |path|
						path = File.expand_path(path)
						root = File.dirname(path)
						
						spawn(path, container, chdir: root)
					end
					
					container.spawn(name: "Falcon Redirector", restart: true, key: :redirect) do |instance|
						instance.exec(falcon_path, "redirect",
							"--bind", evaluator.bind_insecure,
							"--timeout", evaluator.timeout.to_s,
							"--redirect", evaluator.bind_secure,
							*evaluator.configuration_paths, ready: false
						)
					end
					
					container.spawn(name: "Falcon Proxy", restart: true, key: :proxy) do |instance|
						instance.exec(falcon_path, "proxy",
							"--bind", evaluator.bind_secure,
							"--timeout", evaluator.timeout.to_s,
							*evaluator.configuration_paths, ready: false
						)
					end
				end
			end
		end
	end
end
