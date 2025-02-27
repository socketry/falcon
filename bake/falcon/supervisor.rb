# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2025, by Samuel Williams.

def restart
	context.lookup("async:container:supervisor:restart").call
end
