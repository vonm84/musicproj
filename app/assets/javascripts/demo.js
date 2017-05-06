var fullPianoKeyboard = document.getElementById('full');
var fullEvents = document.getElementById('fullEvents');
var fullLog = makeLogger(fullEvents);

// Listening to events
fullPianoKeyboard.addEventListener('noteon', function(e) {
	fullLog(e.detail);
});

function nextchord(){
	document.getElementById('fullEvents').value+="],[";
}

function banksubmit(){
	document.getElementById('fullEvents').value+="]";
	document.getElementById('fullEvents').value="["+document.getElementById('fullEvents').value+"]";
	document.forms[0].submit();
}
function clearbank(){
	document.getElementById('fullEvents').value="";
}

function makeLogger(el) {
	return function(obj) {
		var a = JSON.stringify(obj.index, null, '');
		if (el.value=="") el.value = "[" + a;
		else {
			if (el.value.slice(-1)=='[') el.value = el.value + a; else el.value = el.value + "," + a;}
		
	};
}

