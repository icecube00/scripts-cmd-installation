if (WScript.Arguments.Length < 2) {
	WScript.Echo("Отсутсвуют обязательные параметры.")
} else {
	var oShell = new ActiveXObject("Shell.Application");
	var strPath = trim(WScript.Arguments.Item(0).toString());
	var oFolder = "";
	var oFile = "";
	try {
		oFolder = oShell.Namespace(strPath);
		oFile = oFolder.ParseName(WScript.Arguments.Item(1));
	} catch(e) {
		//No folder object :(
	}
	switch (WScript.Arguments.Length) {
		case 2:
			var Version=getFileVersion(oFolder,oFile);
			WScript.Echo(Version);
			break;
		case 3:
			var locale = WScript.Arguments.Item(2);
			var Version=getFileVersion(oFolder,oFile,locale);
			WScript.Echo(Version);
			break;
		case 4:
			var locale = WScript.Arguments.Item(2);
			var scriptArg = WScript.Arguments.Item(3);
			var Version=getFileVersion(oFolder,oFile,locale,scriptArg);
			WScript.Echo(Version);
			break;
		default:
			var Version=getFileVersion(oFolder,oFile);
			WScript.Echo(Version);
			break;
	}
}

function URIescape(str){
	return encodeURIComponent(str);
}

function getFileVersion(oFolder,oFile,locale,scriptArg){
/*
	var NAME = 0;
	var SIZE = 1;
	var TYPE = 2;
	var MODIFIED = 3;
	var CREATED = 4;
	var ACCESSED = 5;
	var ATTRIBUTES = 6;
	WScript.Echo('getFileVersion('+oFolder+','+oFile +','+locale+','+scriptArg+')');
*/
	var COMPANY, FVERSION, PNAME, PVERSION;
	var strVersion="ERROR: CAN'T FIND FILE VERSION";
	try {
		switch (locale) {
			case 'copied':
				COMPANY=getPropertyId("Company");
				FVERSION=getPropertyId("File Version");
				PNAME=parseInt(getPropertyId("Product Name"));
				PVERSION=parseInt(getPropertyId("Product Version"));
				break;
			case 'скопировано':
				COMPANY=getPropertyId("Производитель");
				FVERSION=getPropertyId("Версия файла");
				PNAME=parseInt(getPropertyId("Название продукта"));
				PVERSION=parseInt(getPropertyId("Версия продукта"));
				break;
			default:
				COMPANY=getPropertyId("Company");
				FVERSION=getPropertyId("File Version");
				PNAME=parseInt(getPropertyId("Product Name"));
				PVERSION=parseInt(getPropertyId("Product Version"));
		}
		switch (scriptArg) {
			case 'fileV':
				if (-99999!=FVERSION) strVersion = oFolder.GetDetailsOf(oFile,FVERSION);
				break;
			case 'productV':
				if (-99999!=PVERSION) strVersion = oFolder.GetDetailsOf(oFile,PVERSION);
				break;
			default:
				if (-99999!=COMPANY) strVersion = oFolder.GetDetailsOf(null,COMPANY) + ": " + oFolder.GetDetailsOf(oFile,COMPANY) + "\r\n";
				if (-99999!=FVERSION) strVersion += oFolder.GetDetailsOf(null,FVERSION) + ": " + oFolder.GetDetailsOf(oFile,FVERSION) + "\r\n";
				if (-99999!=PNAME) strVersion += oFolder.GetDetailsOf(null,PNAME) + ": " + oFolder.GetDetailsOf(oFile,PNAME) + "\r\n";
				if (-99999!=PVERSION) strVersion += oFolder.GetDetailsOf(null,PVERSION) + ": " + oFolder.GetDetailsOf(oFile,PVERSION);
		}
	} catch(e) {
		strVersion="ERROR: " + e.message;
	}
	if (strVersion==="") strVersion="empty";
	return strVersion;
}

function getPropertyId(strPropName){
	var i =7;
	var keepsearching = true;
	var nolimit = true;
	while (keepsearching & nolimit) {
		if (oFolder.GetDetailsOf(null,i).indexOf(strPropName) > -1) keepsearching=false;
		if (i>300) nolimit=false;
		i++;
	}
	if (nolimit) { 
		return(i-1)
	} else {
		return(-99999)
	}
}

function trim(str, charlist) {
	str = !str ? '':str;
	charlist = !charlist ? ' \xA0' : charlist.replace(/([\[\]\(\)\.\?\/\*\{\}\+\$\^\:])/g, '\$1');
	var re = new RegExp('^[' + charlist + ']+|[' + charlist + ']+$', 'g');
	return str.replace(re, '');
}

function Chr(intChar){
	return String.fromCharCode(intChar);
}