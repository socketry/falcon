# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020, by Samuel Williams.

if GC.respond_to?(:compact)
	Console.logger.warn(self, "Compacting the mainframe...")
	GC.compact
	Console.logger.warn(self, "Compacting done...")
end
