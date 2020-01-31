# Copyright, 2019, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require_relative '../extensions/openssl'
require_relative '../controller/proxy'
require_relative '../tls'

add(:tls) do
	ssl_session_id "falcon"
	ssl_ciphers Falcon::TLS::SERVER_CIPHERS
	
	ssl_certificate_path {File.expand_path("ssl/certificate.pem", root)}
	ssl_certificates {OpenSSL::X509.load_certificates(ssl_certificate_path)}
	
	ssl_certificate {ssl_certificates[0]}
	ssl_certificate_chain {ssl_certificates[1..-1]}
	
	ssl_private_key_path {File.expand_path("ssl/private.key", root)}
	ssl_private_key {OpenSSL::PKey::RSA.new(File.read(ssl_private_key_path))}
	
	ssl_context do
		OpenSSL::SSL::SSLContext.new.tap do |context|
			context.add_certificate(ssl_certificate, ssl_private_key, ssl_certificate_chain)
			
			context.session_cache_mode = OpenSSL::SSL::SSLContext::SESSION_CACHE_CLIENT
			context.session_id_context = ssl_session_id
			
			context.alpn_select_cb = lambda do |protocols|
				if protocols.include? "h2"
					return "h2"
				elsif protocols.include? "http/1.1"
					return "http/1.1"
				elsif protocols.include? "http/1.0"
					return "http/1.0"
				else
					return nil
				end
			end
			
			# TODO Ruby 2.4 requires using ssl_version.
			context.ssl_version = :TLSv1_2_server
			
			context.set_params(
				ciphers: ssl_ciphers,
				verify_mode: OpenSSL::SSL::VERIFY_NONE,
			)
			
			context.setup
		end
	end
end
