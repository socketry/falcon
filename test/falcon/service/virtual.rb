# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "falcon/service/virtual"
require "falcon/environment/virtual"
require "async/service/environment"
require "temporary_directory_context"

describe Falcon::Service::Virtual do
	include TemporaryDirectoryContext
	
	let(:environment) do
		Async::Service::Environment.new(Falcon::Environment::Virtual)
	end
	
	let(:service) do
		subject.new(environment)
	end
	
	let(:path) do
		File.join(root, "app", "falcon.rb")
	end
	
	before do
		FileUtils.mkdir_p(File.dirname(path))
		File.write(path, "# test application\n")
	end
	
	it "builds a child environment with path privileges" do
		stat = File.stat(path)
		user = Etc.getpwuid(stat.uid)
		
		expect(Process::GID).to receive(:change_privilege).with(stat.gid)
		expect(Process::UID).to receive(:change_privilege).with(stat.uid)
		
		ENV["BUNDLE_GEMFILE"] = "ignored"
		env = service.assume_privileges(path)
		
		expect(env["BUNDLE_GEMFILE"]).to be == nil
		expect(env["PWD"]).to be == File.dirname(path)
		expect(env["HOME"]).to be == user.dir
	ensure
		ENV.delete("BUNDLE_GEMFILE")
	end
	
	it "spawns an application instance" do
		instance = Class.new do
			def exec(...)
			end
		end.new
		container = Class.new do
			def spawn(...)
			end
		end.new
		
		expect(service).to receive(:assume_privileges).with(path).and_return({"HOME" => root})
		expect(instance).to receive(:exec).with({"HOME" => root}, "bundle", "exec", path, ready: false, chdir: File.dirname(path))
		
		spawn_arguments = nil
		
		mock(container) do |mock|
			mock.replace(:spawn) do |name:, restart:, key:, &block|
				spawn_arguments = {name: name, restart: restart, key: key}
				
				block.call(instance)
			end
		end
		
		service.spawn(path, container, chdir: File.dirname(path))
		
		expect(spawn_arguments).to be == {name: "Falcon Application", restart: true, key: path}
	end
	
	it "sets up application, redirect and proxy instances" do
		environment = Async::Service::Environment.new(Falcon::Environment::Virtual).with(
			configuration_paths: [path],
			resolved_configuration_paths: [path],
			bind_insecure: "http://localhost:8090",
			bind_secure: "https://localhost:8490",
			timeout: 2.0,
			falcon_path: "/usr/bin/falcon",
		)
		service = subject.new(environment)
		
		proxy = Class.new do
			attr :signals
			
			def initialize
				@signals = []
			end
			
			def kill(signal)
				@signals << signal
			end
		end.new
		
		redirect = proxy.class.new
		
		instances = []
		spawns = []
		container = Class.new do
			def initialize(proxy, redirect, instances, spawns)
				@proxy = proxy
				@redirect = redirect
				@instances = instances
				@spawns = spawns
			end
			
			def [](key)
				case key
				when :proxy
					@proxy
				when :redirect
					@redirect
				end
			end
			
			def reload(&block)
				block.call
			end
			
			def spawn(name:, restart:, key:, &block)
				instance = Class.new do
					attr :exec_arguments
					attr :exec_options
					
					def exec(*arguments, **options)
						@exec_arguments = arguments
						@exec_options = options
					end
				end.new
				
				@spawns << {name: name, restart: restart, key: key}
				@instances << instance
				
				block.call(instance)
			end
		end.new(proxy, redirect, instances, spawns)
		
		expect(service).to receive(:assume_privileges).with(path).and_return({"HOME" => root})
		
		service.setup(container)
		
		expect(proxy.signals).to be == [:HUP]
		expect(redirect.signals).to be == [:HUP]
		expect(spawns).to be == [
			{name: "Falcon Application", restart: true, key: path},
			{name: "Falcon Redirector", restart: true, key: :redirect},
			{name: "Falcon Proxy", restart: true, key: :proxy},
		]
		
		expect(instances[0].exec_arguments).to be == [{"HOME" => root}, "bundle", "exec", path]
		expect(instances[0].exec_options).to be == {ready: false, chdir: File.dirname(path)}
		expect(instances[1].exec_arguments).to be == ["/usr/bin/falcon", "redirect", "--bind", "http://localhost:8090", "--timeout", "2.0", "--redirect", "https://localhost:8490", path]
		expect(instances[1].exec_options).to be == {ready: false}
		expect(instances[2].exec_arguments).to be == ["/usr/bin/falcon", "proxy", "--bind", "https://localhost:8490", "--timeout", "2.0", path]
		expect(instances[2].exec_options).to be == {ready: false}
	end
end
