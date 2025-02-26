# frozen_string_literal: true

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
			
			Console.debug(self, "Initializing queue...", limit: limit)
			limit.times{release}
		end
		
		# Release the semaphore.
		def release
			Console.debug(self, "Releasing semaphore...")
			@queue.push(true)
		end
		
		# Acquire the semaphore. May block until the semaphore is available.
		def acquire
			Console.debug(self, "Acquiring semaphore...")
			@queue.pop
			Console.debug(self, "Acquired semaphore...")

			return Token.new(self)
		end
		
		def try_acquire
			if @queue.pop(timeout: 0)
				return Token.new(self)
			end
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
		# Wait for an inbound connection to be ready to be accepted.
		def wait_for_inbound_connection(server)
			semaphore = Semaphore.instance
			
			# Wait until there is a connection ready to be accepted:
			while true
				server.wait_readable
			
				# Acquire the semaphore:
				if token = semaphore.acquire
					return token
				end
			end
		end
		
		# Once the server is readable and we've acquired the token, we can accept the connection (if it's still there).
		def socket_accept_nonblock(server, token)
			result = server.accept_nonblock
			
			success = true
			return result
		rescue IO::WaitReadable
			return nil
		ensure
			token.release unless success
		end
		
		# Accept a connection from the server, limited by the per-worker (thread or process) semaphore.
		def socket_accept(server)
			while true
				if token = wait_for_inbound_connection(server)
					# In principle, there is a connection ready to be accepted:
					socket, address = socket_accept_nonblock(server, token)
					
					if socket
						Console.debug(self, "Accepted connection from #{address.inspect}", socket: socket)
						break
					end
				end
			end
			
			# Identify duplicated sockets:
			# socket.define_singleton_method :dup do
			# 	super().tap do |dup_socket|
			# 		Console.warn(socket, "Duplicating socket!", dup: dup_socket, caller: caller(2..6))
			# 	end
			# end
			
			# Provide access to the token, so that the connection limit could be released prematurely if it is determined that the request will not overload the server:
			socket.define_singleton_method :token do
				token
			end
			
			# Provide a way to release the semaphore when the connection is closed:
			socket.define_singleton_method :close do
				# Force the connection to be closed, even if it was duped:
				# self.shutdown
				
				super()
			ensure
				Console.debug(self, "Releasing connection from #{address.inspect}", socket: socket)
				token.release
			end
			
			success = true
			return socket, address
		ensure
			token&.release unless success
		end
	end
end
