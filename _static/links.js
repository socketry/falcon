jQuery(function() {
	$.each($('section[id]'), function(index, element) {
		let anchor = document.createElement('a');
		
		anchor.appendChild(
			document.createTextNode("¶")
		);
		
		anchor.href = "#" + element.id;
		anchor.className = "self";
		
		let heading = element.firstChild;
		anchor.title = heading.innerText;
		
		heading.appendChild(
			document.createTextNode(' ')
		);
		
		heading.appendChild(anchor);
	});
});
