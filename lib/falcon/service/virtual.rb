# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2026, by Samuel Williams.

require "async/service/generic"
require "console"
require "etc"

module Falcon
	module Service
		# A controller which mananages several virtual hosts.
		# Spawns instances of {Proxy} and {Redirect} to handle incoming requests.
		#
		# A virtual host is an application bound to a specific authority (essentially a hostname). The virtual controller manages multiple hosts and allows a single server to host multiple applications easily.
		class Virtual < Async::Service::Generic
			# Drop privileges according to the user and group of the specified path.
			#
			# The path must be owned by a non-root user who also owns the containing directory. Running an application as root is refused: `File.stat` follows symbolic links, and `bundle exec` evaluates the application's `gems.rb` before the target is loaded, so a user who controls the application directory could otherwise execute arbitrary code as root. The containing directory must have the same owner as the file, since whoever owns the directory can replace the file with arbitrary content.
			#
			# When running as root, the supplementary group list is reset with `Process.initgroups(user.name, stat.gid)`, which yields the user's `/etc/group` memberships plus the file's group; the user's primary group from the passwd entry is only included if it is the file's group or is also listed in `/etc/group`.
			#
			# @parameter path [String] The path to the application's `falcon.rb` configuration file.
			# @returns [Hash] The environment to use for the spawned process.
			# @raises [ArgumentError] If the path is owned by root, the containing directory is owned by a different user, or the owner has no passwd entry.
			def assume_privileges(path)
				# Process.exec / Process.spawn don't replace the environment but instead update it, so we need to clear out any existing BUNDLE_ variables using `nil` values, which will cause them to be removed from the child environment:
				env = ENV.to_h do |key, value|
					if key.start_with?("BUNDLE_")
						[key, nil]
					else
						[key, value]
					end
				end
				
				directory = File.dirname(path)
				env["PWD"] = directory
				
				# `File.stat` follows symbolic links, so this is the owner of the file that will actually be loaded:
				stat = File.stat(path)
				
				if stat.uid == 0
					raise ArgumentError, "Refusing to run #{path} as root!"
				end
				
				# The owner of the directory can replace the file, so it must be the same user:
				directory_stat = File.stat(directory)
				
				if directory_stat.uid != stat.uid
					raise ArgumentError, "Refusing to run #{path} as the containing directory is owned by a different user!"
				end
				
				unless user = Etc.getpwuid(stat.uid)
					raise ArgumentError, "No passwd entry for uid #{stat.uid} (owner of #{path})!"
				end
				
				# Changing the real/effective uid and gid does not touch the supplementary group list, so a process started as root would otherwise retain root's supplementary groups. `initgroups` requires root, so skip it when running unprivileged; in that case `change_privilege` only succeeds if the file is owned by the current user (and group), otherwise it raises `EPERM`:
				if Process.euid == 0
					Process.initgroups(user.name, stat.gid)
				end
				
				Process::GID.change_privilege(stat.gid)
				Process::UID.change_privilege(stat.uid)
				
				env["HOME"] = user.dir
				env["USER"] = user.name
				env["LOGNAME"] = user.name
				
				return env
			end
			
			# Spawn an application instance from the specified path.
			# @parameter path [String] The path to the application's `falcon.rb` configuration file.
			# @parameter container [Async::Container::Generic] The container to spawn into.
			# @parameter options [Options] The options which are passed to `exec`.
			def spawn(path, container, **options)
				container.spawn(name: "Falcon Application", restart: true, key: path) do |instance|
					env = assume_privileges(path)
					
					instance.exec(env, "bundle", "exec", path, ready: false, **options)
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
					
					Console.info(self, "Loading configurations:", paths: evaluator.resolved_configuration_paths)
					
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
