# frozen_string_literal: true

require "async"
require "async/container/group"

module ContainerContext
	def container_context(&block)
		# Newer async-container supervises containers using Async tasks, while
		# released versions can fail when forking under a scheduler on Ruby 3.x.
		if Async::Container::Group.method_defined?(:supervise)
			Sync(&block)
		else
			block.call
		end
	end
end
