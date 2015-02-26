<html><head><title>Kitchen Color Picker</title>
<meta http-equiv="refresh" content="30">
<link rel="stylesheet" type="text/css" href="style.css">
<script type="text/javascript" src="jscolor/jscolor.js"></script>
<script>
	new Colorpicker().insertTo('my-element');
</script>
</head>
<body>
<div id="main">
<h1>The Kitchen LED</h1>
<form method="post" action="kcs.cgi">
<input type="text" id="my-field" />
<input type="submit" id="lightButton" name="light" value="%value%"></form>
</div>
</body></html>
