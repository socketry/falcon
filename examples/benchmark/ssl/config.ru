
require "securerandom"

response = SecureRandom.hex(ENV.fetch('RESPONSE_SIZE', 1024*8).to_i)

puts "response.bytesize = #{response.bytesize}"

run lambda { |env|
	[200, {"Content-Type" => "text/plain"}, [response.dup]]
}
