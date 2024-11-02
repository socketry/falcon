# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2023, by Samuel Williams.

def restart
	require_relative "../../lib/falcon/command/supervisor"
	
	Falcon::Command::Supervisor["restart"].call
end
