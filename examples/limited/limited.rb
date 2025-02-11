module Limited
	# Thread local storage for the semaphore (per-worker):
	Thread.attr_accessor :limited_semaphore
	
	# We use a thread-safe semaphore to limit the number of connections that can be accepted at once.
	class Semaphore
		# Get the semaphore for the current thread.
		def self.instance
			Thread.current.limited_semaphore ||= new
		end
		
		# Create a new semaphore with the given limit.
		def initialize(limit = 1)
			@queue = Thread::Queue.new
			limit.times{release}
		end
		
		# Release the semaphore.
		def release
			@queue.push(true)
		end
		
		# Acquire the semaphore. May block until the semaphore is available.
		def acquire
			@queue.pop
			
			return Token.new(self)
		end
		
		# A token that can be used to release the semaphore once and once only.
		class Token
			def initialize(semaphore)
				@semaphore = semaphore
			end
			
			def release
				if semaphore = @semaphore
					@semaphore = nil
					semaphore.release
				end
			end
		end
	end
	
	# A wrapper implementation for the endpoint that limits the number of connections that can be accepted.
	class Wrapper < IO::Endpoint::Wrapper
		def socket_accept(server)
			semaphore = Semaphore.instance
			
			# Wait until there is a connection ready to be accepted:
			server.wait_readable
			
			# Acquire the semaphore:
			Console.info(self, "Acquiring semaphore...")
			token = semaphore.acquire
			
			# Accept the connection:
			socket, address = super
			Console.info(self, "Accepted connection from #{address.inspect}", socket: socket)
			
			# Provide access to the token, so that the connection limit could be released prematurely if it is determined that the request will not overload the server:
			socket.define_singleton_method :token do
				token
			end
			
			# Provide a way to release the semaphore when the connection is closed:
			socket.define_singleton_method :close do
				super()
			ensure
				Console.info(self, "Closing connection from #{address.inspect}", socket: socket)
				token.release
			end
			
			return socket, address
		end
	end
end
