# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2023, by Samuel Williams.

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
	
	def print_allocations(minimum = 100, output: StringIO.new)
		total = allocations.values.sum
		
		allocations.select{|k,v| v >= minimum}.sort_by{|k,v| k.name}.each do |key, value|
			output.puts "#{key}: #{value} allocations"
		end
		
		output.puts "** Total: #{total} allocations."
		
		return output
	end
	
	def call(env)
		GC.start
		
		if env["PATH_INFO"] == "/allocations"
			return [200, [], [print_allocations.string]]
		else
			print_allocations(output: $stderr)
			
			return @app.call(env)
		end
	end
end
