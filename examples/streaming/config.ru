# frozen_string_literal: true
require "xrb/template"
TEMPLATE = XRB::Template.load(<<~'HTML')
<!DOCTYPE html><html><head><title>99 bottles of beer</title></head><body>
	<?r 99.downto(1) do |i| ?>
	<p>#{i} bottles of beer on the wall</br>
	   <?r sleep 1 ?>#{i} bottles of beer</br>
	   <?r sleep 1 ?>take one down, and pass it around</br>
	   <?r sleep 1 ?>#{i-1} bottles of beer on the wall</br></p>
	<?r end ?>
</body></html>
HTML

run do |env|
	[200, {"content-type" => "text/html"}, TEMPLATE.to_proc]
end