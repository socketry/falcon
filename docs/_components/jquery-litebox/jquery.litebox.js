
(function ($, undefined) {
	function showImage(element, overlay) {
		if (element.href) {
			var image = new Image();
			image.src = element.href;
			overlay.append(image);
		}
	}
	
	$.fn.litebox = function(callback) {
		callback = callback || showImage;
		
		this.on('click', function() {
			var overlay = $('<div class="litebox overlay"></div>');
			
			overlay.on('click', function() {
				overlay.remove();
				$('body').css('overflow', 'auto');
			});
			
			callback(this, overlay);
			
			$('body').css('overflow', 'hidden');
			$('body').append(overlay);
			
			return false;
		});
	}
}(jQuery));
