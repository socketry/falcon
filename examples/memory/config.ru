# frozen_string_literal: true

require_relative "allocations"

use Allocations

run lambda{|env| [200, [], ["Hello World"]]}

# % curl --insecure https://localhost:9292/allocations
# String: 32179 allocations
# Array: 10228 allocations
# Hash: 1299 allocations
# Class: 1118 allocations
# ** Total: 50162 allocations.