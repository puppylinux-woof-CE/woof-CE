/* Puppy specific stuff */

// load stylesheet
var e = document.createElement('link');
e.href = 'c/puppy.css';
e.rel = 'stylesheet';
document.head.appendChild(e);

// load favicon
e = document.createElement('link');
e.href = 'c/puppylogo96.png';
e.rel = 'icon';
e.type = 'image/png';
document.head.appendChild(e);

// unhide when ready
$().loaded(function() {
	document.body.style.display = '';
});

// header and footer
// create header first - important so strapdown.js won't attempt to create its own
var header = document.createElement('div');
document.body.insertBefore(header, document.body.firstChild);
$(header).addClass("navbar"); // this is what strapdown.js is looking for
$().get("c/header.html", function(data) { 
	$(header).html(data);
});

// load header and footer
$().get("c/footer.html", function(data) { 
	var e = document.createElement('div');
	$(e).html(data);
	document.body.appendChild(e);
	
	// update date
	var d = new Date(document.lastModified);
	$("#last-updated").html(d.toDateString());
	
	// contributors list
	var f = location.pathname;
	var i = f.lastIndexOf("/");
	f = f.substring(i+1);
	if (f == "") f += "index.html";
	//console.log(f);
	
	// This makes use of Github API. If hosted else where, this needs to change
	$().get('https://api.github.com/repos/puppylinux-woof-CE/puppylinux-woof-CE.github.io/commits?path='+f,
	function(data) {
		var o = JSON.parse(data);
		var s = {};
		// collect all the unique names.
		for (var i in o) {
			var n = o[i].commit.author.name;
			s[n] = n;
		}
		//console.log(s);		
		o = "";
		for (var n in s) {
			o += ", " + n;
		}
		if (o.length>2) o = o.substring(2);
		//console.log(o);
		$("#contributors").html(o);
		
	}, false, true);
	
});

