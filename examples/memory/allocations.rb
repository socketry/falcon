
class Allocations
	def initialize(app)
		@app = app
	end
	
	def allocations
		counts = Hash.new{|h,k| h[k] = 0}
		
		ObjectSpace.each_object do |object|
			counts[object.class] += 1
		end
		
		return counts
	end
	
	def print_allocations(minimum = 100)
		buffer = StringIO.new
		
		total = allocations.values.sum
		
		allocations.select{|k,v| v >= minimum}.sort_by{|k,v| -v}.each do |key, value|
			buffer.puts "#{key}: #{value} allocations"
		end
		
		buffer.puts "** Total: #{total} allocations."
		
		return buffer.string
	end
	
	def call(env)
		if env["PATH_INFO"] == "/allocations"
			return [200, [], [print_allocations]]
		else
			return @app.call(env)
		end
	end
end
