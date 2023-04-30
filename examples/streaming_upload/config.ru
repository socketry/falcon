# frozen_string_literal: true

# run with: falcon serve -n 1 -b http://localhost:9292

require 'digest'
require 'securerandom'

module Protocol
  module HTTP1
    class Connection
      def write_continue
        @stream.write("HTTP/1.1 100 Continue\r\n\r\n")
        @stream.flush
      end
    end
  end
end

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
        chunk = @input.read(10_240) # read will raise EOF so we have to check
      rescue EOFError
        puts "Seems we're done"
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
  request = env['protocol.http.request']
  handler = BodyHandler.new(env['rack.input'], env['CONTENT_LENGTH'])
  puts "#{env['REQUEST_METHOD']} #{handler.uuid}: #{request.path}  #{env['CONTENT_LENGTH']}"

  if env['REQUEST_METHOD'] == 'POST'
    request.connection.write_continue if request.headers['expect'] == ['100-continue']
    handler.receive
    msg = "Uploaded #{handler.uuid}: #{handler.md5} #{handler.time} #{handler.size}"
    puts msg
    [200, {}, [msg]]
  else
    sleep 1
    [200, {}, ["#{env['REQUEST_METHOD']}: #{request.path}\n"]]
  end
}
