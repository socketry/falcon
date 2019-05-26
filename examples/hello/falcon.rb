#!falcon host

host 'localhost', :rack, :self_signed do
	root __dir__
end
