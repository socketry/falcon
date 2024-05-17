# frozen_string_literal: true

require "pg"
require "falcon/environment/rack"

connection = PG.connect(dbname: "test")
result = connection.exec("SELECT 1")
Console.info(self, "Connection established to PostgreSQL database", result: result.to_a, connection: connection)
connection.close

service "hello.localhost" do
	include Falcon::Environment::Rack
	
	endpoint do
		Async::HTTP::Endpoint.parse("http://hello.localhost:9292")
	end
	
	preload "preload.rb"
end
