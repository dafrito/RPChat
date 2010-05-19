var messageBuffer;
var dummyElement;

function addValue(value) {
	messageBuffer = messageBuffer || document.getElementById("messageBuffer");
	dummyElement = dummyElement || document.createElement("span");
	dummyElement.innerHTML = value;
	messageBuffer.appendChild(dummyElement.removeChild(dummyElement.childNodes[0]));
}

function clearValues() {
	messageBuffer.innerHTML = "";
}