# frozen_string_literal: true

# This echos the body back.
run lambda { |env| [200, {}, [env['rack.input'].read]] }
