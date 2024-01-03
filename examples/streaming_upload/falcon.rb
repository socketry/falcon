load :rack, :supervisor

hostname = File.basename(__dir__)
rack hostname do
	endpoint Async::HTTP::Endpoint.parse('http://localhost:9292').with(protocol: Async::HTTP::Protocol::HTTP1)
end

supervisor
