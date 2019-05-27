#!falcon host

host 'hello.localhost', :rack, :self_signed do
	root __dir__
	
	endpoint do
		Async::HTTP::Endpoint.parse("http://localhost:9292")
	end
end

# service 'jobs' do
# 	shell ['rake', 'background:jobs:process']
# end
