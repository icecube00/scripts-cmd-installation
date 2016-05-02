var wbemFlagReturnImmediately = 0x10;
var wbemFlagForwardOnly = 0x20;

var objWMIService = GetObject("winmgmts:\\\\.\\root\\CIMV2");
var colItems = objWMIService.ExecQuery("SELECT * FROM CIM_VideoControllerResolution", "WQL",
                                          wbemFlagReturnImmediately | wbemFlagForwardOnly);
var enumItems = new Enumerator(colItems);
var resolutionCollection = [];

for (; !enumItems.atEnd(); enumItems.moveNext()) {
	var objItem = enumItems.item();
	var rating = ((objItem.VerticalResolution * objItem.HorizontalResolution)+objItem.NumberOfColors)
	var obj={};
	obj["rating"]=rating;
	obj["resolution"]=objItem.SettingID;
	resolutionCollection.push(obj);
}

var a = resolutionCollection.sort(function(x,y){return (x.rating-y.rating)}).pop();
WScript.Echo (a.resolution);

function byKey(a,b) {
	var keyA=parseInt(a.rating);
	var keyB=parseInt(b.rating);
	if (keyA<keyB) return -1;
	if (keyA>keyB) return 1;
	return 0;
}