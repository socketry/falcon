# frozen_string_literal: true

require "trenni"

class Output < Struct.new(:stream)
	def <<(chunk)
		stream.call chunk
	end
end

class DeferredBody < Struct.new(:later)
	def each(&stream)
		later.call(stream)
	end
end

class App
	def call(env)
		buffer = Trenni::Buffer.new(<<-EOF)
		<?r 10.times do; sleep 1 ?>
		Hello World
		<?r end ?>
		EOF
		
		template = Trenni::Template.new(buffer)
		body = DeferredBody.new(->(stream){ template.to_string({}, Output.new(stream)) })
		
		[200, {}, body]
	end
end

run App.new
