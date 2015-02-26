<html>
<head><title>Esp8266 web server</title>
<link rel="stylesheet" type="text/css" href="style.css">
</head>
<script>
function updateValue(value, index) {
	var button = document.getElementById('lightButton');
	button.value = ((button.value & ~(0xFF << 8 * (index - 1)))) | (value << 8 * (index - 1));
	button.click();
}
</script>
<body>
<div id="main">
<h1>It Works</h1>
<p>
If you see this, it means the tiny li'l website in your ESP8266 does actually work. Fyi, this page has
been loaded <b>%counter%</b> times.
<ul>
<li>If you haven't connected this device to your WLAN network now, you can <a href="/wifi">do so.</a></li>
<li>You can also control the <a href="led.tpl">LED</a>.</li>
<li><a href="kcs.tpl">Kitchen Light Selector</a>.</li>
<li>You can download the raw <a href="flash.bin">contents</a> of the SPI flash rom</li>
</ul>
</p>

<form name="lightform" method="post" action="light.cgi">
<div id="light">
<label for="slider1">R:</label>
<input type="range" id="slider1" min="0" max="255" step="1" value="%value1%" onchange="updateValue(this.value, 1)">
<label for="slider2">G:</label>
<input type="range" id="slider2" min="0" max="255" step="1" value="%value2%" onchange="updateValue(this.value, 2)">
<label for="slider3">B:</label>
<input type="range" id="slider3" min="0" max="255" step="1" value="%value3%" onchange="updateValue(this.value, 3)">
<label for="slider4">W:</label>
<input type="range" id="slider4" min="0" max="255" step="1" value="%value4%" onchange="updateValue(this.value, 4)">
</div>
<input type="submit" style="visibility: hidden;" id="lightButton" name="light" text="OK" value="%value%">
</form>
</p>
</div>
</body></html>
