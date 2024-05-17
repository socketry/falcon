# frozen_string_literal: true

require "falcon/environment/rack"

service "hello.localhost" do
	include Falcon::Environment::Rack
end
