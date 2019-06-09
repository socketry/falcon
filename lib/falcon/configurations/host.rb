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

load(:ssl)

add(:host, :ssl) do
	ssl_certificate_path {File.expand_path("ssl/certificate.pem", root)}
	ssl_certificate {OpenSSL::X509::Certificate.new(File.read(ssl_certificate_path))}
	
	ssl_private_key_path {File.expand_path("ssl/private.key", root)}
	ssl_private_key {OpenSSL::PKey::RSA.new(File.read(ssl_private_key_path))}
	
	ssl_context do
		OpenSSL::SSL::SSLContext.new.tap do |context|
			context.cert = ssl_certificate
			context.key = ssl_private_key
			
			context.session_id_context = ssl_session_id
			
			context.set_params(
				verify_mode: OpenSSL::SSL::VERIFY_NONE,
			)
			
			context.setup
		end
	end
end
