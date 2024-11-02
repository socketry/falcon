# frozen_string_literal: true

require "cgi"

# curl 'http://localhost:9292/?xid=1%0DSet-Cookie:%20foo%3Dbar'

run ->(env) {
	params = CGI.parse env["QUERY_STRING"]
	header = params.fetch("xid", []).first || ""
	
	[200, {"xid" => "m" + header }, ["hello"]]
}