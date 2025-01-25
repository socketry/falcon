# frozen_string_literal: true

run do |env|
	[200, {}, ["Hello World! #{Time.now}"]]
end
