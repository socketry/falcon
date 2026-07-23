# falcon.rb

load :rack, :tls

rack 'localhost', :tls do
  endpoint do
    Async::HTTP::Endpoint.for(scheme, 'localhost', port: '3000', ssl_context: ssl_context)
  end

  ssl_certificate_path { 'certificate.pem' }
  ssl_private_key_path { 'private.key' }
end

