# frozen_string_literal: true

class EchoBody
	def initialize(input)
		@input = input
	end

	def each(&output)
		while chunk = @input.read(1024)
			output.call(chunk)
		end
	end
end

run lambda{|env|
	[200, [], EchoBody.new(env["rack.input"])]
}
