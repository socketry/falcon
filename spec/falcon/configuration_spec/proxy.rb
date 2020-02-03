# frozen_string_literal: true

load :proxy

proxy 'localhost' do
	url 'https://www.google.com'
end
