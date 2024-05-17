# frozen_string_literal: true

require "pg"

run do |env|
	connection = PG.connect(dbname: "test")
	result = connection.exec("SELECT 1")
	Console.info(self, "Connection established to PostgreSQL database", result: result.to_a, connection: connection)
	connection.close
	
	[200, {"content-type" => "text/plain"}, ["Hello, World!"]]
end
