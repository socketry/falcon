# frozen_string_literal: true

# run with: falcon serve -n 1 -b http://localhost:9292

require "digest"
require "securerandom"

class BodyHandler
	attr_reader :time, :md5, :size, :uuid

	def initialize(input, length)
		@uuid = SecureRandom.uuid
		@input = input
		@length = length
	end

	def receive
		start = Time.now
		@md5 = Digest::MD5.new
		@size = 0
		@done = false

		until @done
			begin
				chunk = @input.read(1024*1024) # read will raise EOF so we have to check
			rescue EOFError
				Console.info(self, "Received EOF")
				chunk = nil
			end
			
			if chunk.nil?
				@done = true
			else
				@md5.update(chunk)
				@size += chunk.bytesize
				@done = true if @length == @size
			end
		end

		@time = Time.now - start
	end
end

run lambda { |env|
	request = env["protocol.http.request"]
	handler = BodyHandler.new(env["rack.input"], env["CONTENT_LENGTH"])
	Console.info(self, "#{env['REQUEST_METHOD']} #{handler.uuid}: #{request.path}  #{env['CONTENT_LENGTH']}")
	
	if env["REQUEST_METHOD"] == "POST"
		if request.headers["expect"]&.include?("100-continue")
			request.write_interim_response(Protocol::HTTP::Response[100])
		end
		
		handler.receive
		
		Console.info(handler, "Received #{handler.size} bytes in #{handler.time} seconds", uuid: handler.uuid, md5: handler.md5)
		
		[200, {}, ["Uploaded #{handler.uuid}: #{handler.md5} #{handler.time} #{handler.size}"]]
	else
		sleep 1
		[200, {}, ["#{env['REQUEST_METHOD']}: #{request.path}\n"]]
	end
}
