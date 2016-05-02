var IE=new ActiveXObject("InternetExplorer.application");
IE.Navigate ("about:blank");
while (IE.Busy) {
	WScript.Sleep(200);
}
var window = IE.document.parentWindow.screen
WScript.Echo (window.width + 'X' + window.height);