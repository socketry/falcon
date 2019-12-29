
if GC.respond_to?(:compact)
	Async.logger.warn(self, "Compacting the mainframe...")
	GC.compact
	Async.logger.warn(self, "Compacting done...")
end
