
app = proc do |env|
	[200, {}, ["Hello World"]]
end

run app
