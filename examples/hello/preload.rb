# frozen_string_literal: true

if GC.respond_to?(:compact)
	Console.logger.warn(self, "Compacting the mainframe...")
	GC.compact
	Console.logger.warn(self, "Compacting done...")
end
