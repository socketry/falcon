# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "falcon/service/virtual"
require "falcon/environment/virtual"
require "async/service/environment"
require "sus/fixtures/temporary_directory_context"

describe Falcon::Service::Virtual do
	include Sus::Fixtures::TemporaryDirectoryContext
	
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
	
	with "#assume_privileges" do
		let(:stat) {File.stat(path)}
		let(:user) {Etc.getpwuid(stat.uid)}
		
		def record_privilege_changes(euid)
			calls = []
			
			mock(Process) do |mock|
				mock.replace(:euid){euid}
				mock.replace(:initgroups) do |*arguments|
					calls << [:initgroups, *arguments]
				end
			end
			
			mock(Process::GID) do |mock|
				mock.replace(:change_privilege) do |*arguments|
					calls << [:gid, *arguments]
				end
			end
			
			mock(Process::UID) do |mock|
				mock.replace(:change_privilege) do |*arguments|
					calls << [:uid, *arguments]
				end
			end
			
			return calls
		end
		
		# Replace `File.stat` so that ownership checks can be exercised without changing real file ownership.
		# @parameter owners [Hash(String, Integer)] The uid to report for each path.
		def mock_file_owners(owners)
			stat_class = Struct.new(:uid, :gid)
			
			mock(File) do |mock|
				mock.replace(:stat) do |path|
					stat_class.new(owners.fetch(path), owners.fetch(path))
				end
			end
		end
		
		it "refuses to run an application owned by root" do
			calls = record_privilege_changes(0)
			mock_file_owners(path => 0, File.dirname(path) => 0)
			
			expect do
				service.assume_privileges(path)
			end.to raise_exception(ArgumentError, message: be =~ /Refusing to run .* as root/)
			
			expect(calls).to be(:empty?)
		end
		
		it "refuses to run an application whose directory is owned by a different user" do
			calls = record_privilege_changes(0)
			mock_file_owners(path => 1000, File.dirname(path) => 1001)
			
			expect do
				service.assume_privileges(path)
			end.to raise_exception(ArgumentError, message: be =~ /owned by a different user/)
			
			expect(calls).to be(:empty?)
		end
		
		it "refuses to run an application whose owner has no passwd entry" do
			calls = record_privilege_changes(0)
			expect(Etc).to receive(:getpwuid).with(stat.uid).and_return(nil)
			
			expect do
				service.assume_privileges(path)
			end.to raise_exception(ArgumentError, message: be =~ /No passwd entry for uid #{stat.uid}/)
			
			expect(calls).to be(:empty?)
		end
		
		it "builds a child environment with path privileges" do
			expect(Process).to receive(:euid).and_return(1000)
			expect(Process::GID).to receive(:change_privilege).with(stat.gid)
			expect(Process::UID).to receive(:change_privilege).with(stat.uid)
			
			mock(ENV) do |mock|
				mock.replace(:to_h) do |&block|
					{"BUNDLE_GEMFILE" => "ignored", "PATH" => "/bin"}.to_h(&block)
				end
			end
			
			env = service.assume_privileges(path)
			
			expect(env["BUNDLE_GEMFILE"]).to be == nil
			expect(env["PATH"]).to be == "/bin"
			expect(env["PWD"]).to be == File.dirname(path)
			expect(env["HOME"]).to be == user.dir
			expect(env["USER"]).to be == user.name
			expect(env["LOGNAME"]).to be == user.name
		end
		
		it "resets supplementary groups before dropping privileges when running as root" do
			calls = record_privilege_changes(0)
			
			service.assume_privileges(path)
			
			expect(calls).to be == [
				[:initgroups, user.name, stat.gid],
				[:gid, stat.gid],
				[:uid, stat.uid],
			]
		end
		
		it "does not reset supplementary groups when running unprivileged" do
			calls = record_privilege_changes(1000)
			
			service.assume_privileges(path)
			
			expect(calls).to be == [
				[:gid, stat.gid],
				[:uid, stat.uid],
			]
		end
	end
	
	with "#spawn" do
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
	end
	
	with "#setup" do
		def inline_child
			Class.new do
				attr :signals
				attr :exec_arguments
				attr :exec_options
				
				def initialize
					@signals = []
				end
				
				def kill(signal)
					@signals << signal
				end
				
				def exec(*arguments, **options)
					@exec_arguments = arguments
					@exec_options = options
				end
			end.new
		end
		
		def inline_container(existing, children)
			make_child = method(:inline_child)
			
			Object.new.tap do |container|
				container.define_singleton_method(:[]) do |key|
					existing[key]
				end
				
				container.define_singleton_method(:reload) do |&block|
					block.call
				end
				
				container.define_singleton_method(:spawn) do |name:, restart:, key:, &block|
					child = existing[key] = make_child.call
					
					children << {name: name, restart: restart, key: key, child: child}
					
					block.call(child)
				end
			end
		end
		
		it "reloads redirect and proxy instances" do
			falcon_path = File.join(root, "bin", "falcon")
			environment = Async::Service::Environment.new(Falcon::Environment::Virtual).with(
				configuration_paths: [path],
				resolved_configuration_paths: [path],
				bind_insecure: "http://localhost:8090",
				bind_secure: "https://localhost:8490",
				timeout: 2.0,
				falcon_path: falcon_path,
			)
			service = subject.new(environment)
			proxy = inline_child
			redirect = inline_child
			existing = {proxy: proxy, redirect: redirect}
			children = []
			container = inline_container(existing, children)
			
			expect(service).to receive(:assume_privileges).with(path).and_return({"HOME" => root})
			
			service.setup(container)
			
			expect(proxy).to have_attributes(signals: be == [:HUP])
			expect(redirect).to have_attributes(signals: be == [:HUP])
			expect(children).to have_value(
				have_keys(
					name: be == "Falcon Redirector",
					restart: be == true,
					key: be == :redirect,
					child: have_attributes(
						exec_arguments: be == [falcon_path, "redirect", "--bind", "http://localhost:8090", "--timeout", "2.0", "--redirect", "https://localhost:8490", path],
						exec_options: be == {ready: false},
					),
				)
			)
			expect(children).to have_value(
				have_keys(
					name: be == "Falcon Proxy",
					restart: be == true,
					key: be == :proxy,
					child: have_attributes(
						exec_arguments: be == [falcon_path, "proxy", "--bind", "https://localhost:8490", "--timeout", "2.0", path],
						exec_options: be == {ready: false},
					),
				)
			)
		end
	end
end
