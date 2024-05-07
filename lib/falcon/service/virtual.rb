# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2024, by Samuel Williams.

require 'async/service/generic'

module Falcon
	module Service
		# A controller which mananages several virtual hosts.
		# Spawns instances of {Proxy} and {Redirect} to handle incoming requests.
		#
		# A virtual host is an application bound to a specific authority (essentially a hostname). The virtual controller manages multiple hosts and allows a single server to host multiple applications easily.
		class Virtual < Async::Service::Generic
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
					falcon_path = evaluator.falcon_path
					
					Console.info(self, "Loading configurations from:", evaluator.resolved_configuration_paths)
					
					evaluator.resolved_configuration_paths.each do |path|
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
