# frozen_string_literal: true

run do |env|
	if input = env["rack.input"]
		data = input.read
		Console.info(self, "Received #{data.bytesize} bytes")
	end
	
	[204, {}, []]
end
