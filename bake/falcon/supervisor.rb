# frozen_string_literal: true

# Restart the application server via the supervisor.
def restart
	require_relative '../../lib/falcon/command/supervisor'
	
	Falcon::Command::Supervisor["restart"].call
end
