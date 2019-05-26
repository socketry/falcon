#!falcon host

host 'hello.localhost', :rack, :self_signed do
	root __dir__
end

# service 'jobs' do
# 	shell ['rake', 'background:jobs:process']
# end
