
require "pg"

connection = PG.connect(dbname: "test")
result = connection.exec("SELECT 1")
Console.info(self, "Connection established to PostgreSQL database", result: result.to_a, connection: connection)
connection.close
