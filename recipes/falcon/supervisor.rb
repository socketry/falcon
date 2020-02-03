# frozen_string_literal: true

recipe :restart, description: 'Restart the application server via the supervisor.' do
	require_relative '../../lib/falcon/command/supervisor'
	
	Falcon::Command::Supervisor["restart"].call
end
