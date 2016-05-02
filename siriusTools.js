//----------------------------------------------------------------------
// Сборник утилит
//----------------------------------------------------------------------
var version='1.00.000';
objShell = new ActiveXObject("Shell.Application"); //ActiveX-объект оболочки исполнения JS скриптов
var wshShell = WScript.CreateObject("WScript.Shell");//Оболочка среды исполнения JS скриптов
var FSO = new ActiveXObject("Scripting.FileSystemObject");//ActiveX-объект для доступа к файловой системе
var hex_chr = '0123456789abcdef'.split('');

// Объявление прототипа indexOf для массивов (необходим для IE<9)
if (!Array.prototype.indexOf) {
	Array.prototype.indexOf=function(searchElement, fromIndex) {
		if(this === undefined || this === null) throw new TypeError('"Array.prototype.indexOf" is NULL or not defined');
		var length = this.length >>> 0; //Convert object.length to UInt32
		fromIndex=+fromIndex||0;
		if(Math.abs(fromIndex)===Infinity) fromIndex=0;
		if(fromIndex<0){
			fromIndex +=length;
			if(fromIndex<0){
				fromIndex=0;
			}
		}
		for(;fromIndex<length;fromIndex++) {
			if(this[fromIndex]===searchElement) return fromIndex;
		}
		return -1;
	};
}

// Объявление прототипа isEmpty для строк
if (!String.prototype.isEmpty) {
	String.prototype.isEmpty=function(){
		if(this === undefined || this === null) throw new TypeError('"String.prototype.isEmpty" is NULL or not defined');
		var length = this.length;
		if (length<1) return true;
		return false;
	}
}

// Проверка механизма подсчета MD5 (глюки винды и IE)
if (md5('hello') != '5d41402abc4b2a76b9719d911017c592') {
	function add32(x, y) {
		var lsw = (x & 0xFFFF) + (y & 0xFFFF), 
			msw = (x >> 16) + (y >> 16) + (lsw >> 16);
		return (msw << 16) | (lsw & 0xFFFF);
	}
}

if (WScript.Arguments.Length < 1) {
	WScript.Echo("ERROR: Некорректный вызов утилиты.");
	showHelp();
} else {
	switch (getCMDparameter('',0).toString()) {
		case 'setHosts':
			switch (WScript.Arguments.Length) {
				case 2:
					setHosts(getCMDparameter('setHosts',1), "127.0.0.1");
					break;
				case 3:
					setHosts(getCMDparameter('setHosts',1), getCMDparameter('setHosts',2));
					break;
				default:
					showHelp('setHosts');
					break;
			}
			break;
		case 'installFont':
			var strFileName='', strFolderName='';
			strFileName = getCMDparameter('installFont',1).toString();
			if (!strFileName.isEmpty()) strFolderName = getCMDparameter('installFont',2).toString();
			if (!strFolderName.isEmpty()) installFonts(strFileName, strFolderName);
			break;
		case 'checkFileVersion':
			var strPath = trim(getCMDparameter('checkFileVersion',1).toString());
			if (!strPath.isEmpty()) {
				var oFolder = "";
				var oFile = "";
				try {
					oFolder = objShell.Namespace(strPath);
					oFile = oFolder.ParseName(getCMDparameter('checkFileVersion',2));
				} catch(e) {
					/* No folder object */
				}
				switch (WScript.Arguments.Length) {
					case 3:
						var Version=getFileVersion(oFolder,oFile);
						WScript.Echo(Version);
						break;
					case 4:
						var locale = getCMDparameter('checkFileVersion',3);
						var Version=getFileVersion(oFolder,oFile,locale);
						WScript.Echo(Version);
						break;
					case 5:
						var locale = getCMDparameter('checkFileVersion',3);
						var scriptArg = getCMDparameter('checkFileVersion',4);
						var Version=getFileVersion(oFolder,oFile,locale,scriptArg);
						WScript.Echo(Version);
						break;
					default:
						var Version=getFileVersion(oFolder,oFile);
						WScript.Echo(Version);
						break;
				}
			}
			break;
		case 'calcHASH':
			var fileName = getCMDparameter('calcHASH',1);	//Full file name
			if(!fileName.isEmpty()) {
				var adoStream = new ActiveXObject("ADODB.Stream");
				try {
					if(!FSO.FolderExists(fileName)) {
						adoStream.CharSet = 'utf-8';
						adoStream.Open();
						adoStream.LoadFromFile(fileName);
						var m5file='';
						m5file=adoStream.ReadText(100000);
						WScript.Echo (fileName + '\t' + md5(m5file));
						adoStream.Close();
					}
				} catch (e) {
					WScript.Echo (fileName + "\tNO MD5 HASH COULD BE CALCULATED" + "\r\n\tERR Name: " + e.name + "\r\n\tERR Text: " + e.message);
				}
			}
			break;
		case 'getPath':
			var isVariableSet=false, pathReturned=''
			var fileName='', folderPath='',isParent='';
			fileName = getCMDparameter('getPath',1);	//File name
			if (!fileName.isEmpty()) folderPath = getCMDparameter('getPath',2);	//Full folder name
			if (!folderPath.isEmpty()) isParent = getCMDparameter('getPath',3);	//Should return a parent folder (Level up)
			if (!isParent.isEmpty()) pathReturned=getPath(fileName,folderPath,eval(isParent));
			WScript.Echo(pathReturned);
			break;
		case 'setEnvVar':
			var varName='', varValue='',probablePath='';
			var isAdd=true;
			varName = getCMDparameter('setEnvVar',1);
			switch (WScript.Arguments.Length) {	
				case 2:
					break;
				case 3:
					varValue = getCMDparameter('setEnvVar',2);
					break;
				default:
					if(WScript.Arguments.Item(WScript.Arguments.Length-1)=="remove") {
						isAdd=false;
					} else {
						for(var i=2;i<WScript.Arguments.Length;i++) {
							probablePath = trim(probablePath + " " + WScript.Arguments.Item(i));
						}
						if (!FSO.FolderExists(probablePath)) WScript.Echo("Переданный путь не существует - " + probablePath);
						varValue=probablePath;
					}
			}
			var res=setEnvVariable(varName, varValue, isAdd);
			if (res && !isAdd) WScript.Echo("Переменная окружения - " + varName + " была удалена.");
			if (res && isAdd && !varValue.isEmpty()) WScript.Echo("Переменной окружения - " + varName + " было присвоено значение " + varValue +".");
			break;
		case 'createShCut':
			var allUserFolder=getCMDparameter('createShCut',1);
			var tomcatHome=getCMDparameter('createShCut',2);
			if(FSO.FolderExists(allUserFolder + "\\Start Menu\\Programs\\Startup") && FSO.FolderExists(tomcatHome + "\\bin")) {
				var result = setShortCut(allUserFolder, tomcatHome);
				if (result) {
					WScript.Echo("Создана новая ссылка на файл.");
				} else {
					WScript.Echo("Не удалось создать ссылку на файл.");
				}
			} else {
				WScript.Echo("Не найдена папка для создания ссылки." + "\r\n" + 
					 allUserFolder + "\\Start Menu\\Programs\\Startup" + " = " + FSO.FolderExists(allUserFolder + "\\Start Menu\\Programs\\Startup") + "\r\n" +
					 tomcatHome + "\\bin" + " = " + FSO.FolderExists(tomcatHome + "\\bin"));
			}
			break;
		default:
			showHelp();
	}
}

function installFonts(strFile, strFolder) {
	
	var destFolder, fromFolder, oFile;
	var isBatchInstall;
		 
	if (strFile.indexOf("*")>-1) isBatchInstall = true;
	var FONTS = 0x14;
	
	var szFolder = wshShell.SpecialFolders("FONTS");
	destFolder = objShell.NameSpace(szFolder);
	fromFolder = FSO.GetFolder(strFolder);
	if(isBatchInstall) {
		for (oFile in fromFolder.Files()) {
			installWindowsFont(destFolder, fromFolder, oFile);
		}
	} else {
		if (FSO.FileExists(fromFolder + '\\' + strFile )) {
			oFile = FSO.GetFile(fromFolder + '\\' + strFile);
			installWindowsFont(destFolder, fromFolder, oFile);
		} else {
			WScript.Echo ("WARN: Шрифт " + strFile + " не найден")
		}
	}
	destFolder = null;
	fromFolder = null;
	objShell = null;
}

function installWindowsFont(oDestFolder, oFolder, oFile) {
	if (FSO.FileExists(oDestFolder.Self.Path + "\\" + oFile.Name)) {
		WScript.Echo("WARN: Шрифт " + oFile.Name + " уже установлен.");
	} else {
		if (checkExt(oFile.Path,"fon,ttf")) {
			try {
				oDestFolder.CopyHere(oFolder.Path + "\\" + oFile.Name,20);
				WScript.Echo("Шрифт " + oFile.Name + " успешно установлен.");
			} catch(e) {
				WScript.Echo("ERROR: Не удалось установить шрифт: " + oFile.Name + "\r\n\tERR Name: " + e.name + "\r\n\tERR Text: " + e.message);
			}
		} else {
			WScript.Echo("WARN: Недопустимое расширение файла: " + oFile.Name + "");
		}
	}
}

function checkExt(fileName,extArr) {
	var result=true;
	var arrExtensions = extArr.split(",");
	if (arrExtensions.indexOf(fileName.split('.').pop())===-1) {
		result=false;
	}
	return result;
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
*/

	var COMPANY, FVERSION, PNAME, PVERSION;
	var strVersion="ERROR: CAN'T FIND FILE VERSION";
	try {
		switch (locale) {
			case 'copied':
				COMPANY=getPropertyId("Company",oFolder);
				FVERSION=getPropertyId("File Version",oFolder);
				PNAME=parseInt(getPropertyId("Product Name",oFolder));
				PVERSION=parseInt(getPropertyId("Product Version",oFolder));
				break;
			case 'скопировано':
				COMPANY=getPropertyId("Производитель",oFolder);
				FVERSION=getPropertyId("Версия файла",oFolder);
				PNAME=parseInt(getPropertyId("Название продукта",oFolder));
				PVERSION=parseInt(getPropertyId("Версия продукта",oFolder));
				break;
			default:
				COMPANY=getPropertyId("Company",oFolder);
				FVERSION=getPropertyId("File Version",oFolder);
				PNAME=parseInt(getPropertyId("Product Name",oFolder));
				PVERSION=parseInt(getPropertyId("Product Version",oFolder));
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
	if (strVersion.isEmpty()) strVersion="empty";
	return strVersion;
}

function getPropertyId(strPropName,folderObj){
	var i =7;
	var keepsearching = true;
	var nolimit = true;
	while (keepsearching & nolimit) {
		if (folderObj.GetDetailsOf(null,i).indexOf(strPropName) > -1) keepsearching=false;
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

function md5cycle(x, k) {
	var a = x[0], b = x[1], c = x[2], d = x[3];

	a = ff(a, b, c, d, k[0], 7, -680876936);
	d = ff(d, a, b, c, k[1], 12, -389564586);
	c = ff(c, d, a, b, k[2], 17,  606105819);
	b = ff(b, c, d, a, k[3], 22, -1044525330);
	a = ff(a, b, c, d, k[4], 7, -176418897);
	d = ff(d, a, b, c, k[5], 12,  1200080426);
	c = ff(c, d, a, b, k[6], 17, -1473231341);
	b = ff(b, c, d, a, k[7], 22, -45705983);
	a = ff(a, b, c, d, k[8], 7,  1770035416);
	d = ff(d, a, b, c, k[9], 12, -1958414417);
	c = ff(c, d, a, b, k[10], 17, -42063);
	b = ff(b, c, d, a, k[11], 22, -1990404162);
	a = ff(a, b, c, d, k[12], 7,  1804603682);
	d = ff(d, a, b, c, k[13], 12, -40341101);
	c = ff(c, d, a, b, k[14], 17, -1502002290);
	b = ff(b, c, d, a, k[15], 22,  1236535329);

	a = gg(a, b, c, d, k[1], 5, -165796510);
	d = gg(d, a, b, c, k[6], 9, -1069501632);
	c = gg(c, d, a, b, k[11], 14,  643717713);
	b = gg(b, c, d, a, k[0], 20, -373897302);
	a = gg(a, b, c, d, k[5], 5, -701558691);
	d = gg(d, a, b, c, k[10], 9,  38016083);
	c = gg(c, d, a, b, k[15], 14, -660478335);
	b = gg(b, c, d, a, k[4], 20, -405537848);
	a = gg(a, b, c, d, k[9], 5,  568446438);
	d = gg(d, a, b, c, k[14], 9, -1019803690);
	c = gg(c, d, a, b, k[3], 14, -187363961);
	b = gg(b, c, d, a, k[8], 20,  1163531501);
	a = gg(a, b, c, d, k[13], 5, -1444681467);
	d = gg(d, a, b, c, k[2], 9, -51403784);
	c = gg(c, d, a, b, k[7], 14,  1735328473);
	b = gg(b, c, d, a, k[12], 20, -1926607734);

	a = hh(a, b, c, d, k[5], 4, -378558);
	d = hh(d, a, b, c, k[8], 11, -2022574463);
	c = hh(c, d, a, b, k[11], 16,  1839030562);
	b = hh(b, c, d, a, k[14], 23, -35309556);
	a = hh(a, b, c, d, k[1], 4, -1530992060);
	d = hh(d, a, b, c, k[4], 11,  1272893353);
	c = hh(c, d, a, b, k[7], 16, -155497632);
	b = hh(b, c, d, a, k[10], 23, -1094730640);
	a = hh(a, b, c, d, k[13], 4,  681279174);
	d = hh(d, a, b, c, k[0], 11, -358537222);
	c = hh(c, d, a, b, k[3], 16, -722521979);
	b = hh(b, c, d, a, k[6], 23,  76029189);
	a = hh(a, b, c, d, k[9], 4, -640364487);
	d = hh(d, a, b, c, k[12], 11, -421815835);
	c = hh(c, d, a, b, k[15], 16,  530742520);
	b = hh(b, c, d, a, k[2], 23, -995338651);

	a = ii(a, b, c, d, k[0], 6, -198630844);
	d = ii(d, a, b, c, k[7], 10,  1126891415);
	c = ii(c, d, a, b, k[14], 15, -1416354905);
	b = ii(b, c, d, a, k[5], 21, -57434055);
	a = ii(a, b, c, d, k[12], 6,  1700485571);
	d = ii(d, a, b, c, k[3], 10, -1894986606);
	c = ii(c, d, a, b, k[10], 15, -1051523);
	b = ii(b, c, d, a, k[1], 21, -2054922799);
	a = ii(a, b, c, d, k[8], 6,  1873313359);
	d = ii(d, a, b, c, k[15], 10, -30611744);
	c = ii(c, d, a, b, k[6], 15, -1560198380);
	b = ii(b, c, d, a, k[13], 21,  1309151649);
	a = ii(a, b, c, d, k[4], 6, -145523070);
	d = ii(d, a, b, c, k[11], 10, -1120210379);
	c = ii(c, d, a, b, k[2], 15,  718787259);
	b = ii(b, c, d, a, k[9], 21, -343485551);

	x[0] = add32(a, x[0]);
	x[1] = add32(b, x[1]);
	x[2] = add32(c, x[2]);
	x[3] = add32(d, x[3]);

}

function cmn(q, a, b, x, s, t) {
	a = add32(add32(a, q), add32(x, t));
	return add32((a << s) | (a >>> (32 - s)), b);
}

function ff(a, b, c, d, x, s, t) {
	return cmn((b & c) | ((~b) & d), a, b, x, s, t);
}

function gg(a, b, c, d, x, s, t) {
	return cmn((b & d) | (c & (~d)), a, b, x, s, t);
}

function hh(a, b, c, d, x, s, t) {
	return cmn(b ^ c ^ d, a, b, x, s, t);
}

function ii(a, b, c, d, x, s, t) {
	return cmn(c ^ (b | (~d)), a, b, x, s, t);
}

function md51(s) {
	txt = '';
	var n = s.length,
	state = [1732584193, -271733879, -1732584194, 271733878], i;
	for (i=64; i<=s.length; i+=64) {
		md5cycle(state, md5blk(s.substring(i-64, i)));
	}
	s = s.substring(i-64);
	var tail = [0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0];
	for (i=0; i<s.length; i++)
		tail[i>>2] |= s.charCodeAt(i) << ((i%4) << 3);
	tail[i>>2] |= 0x80 << ((i%4) << 3);
	if (i > 55) {
		md5cycle(state, tail);
		for (i=0; i<16; i++) tail[i] = 0;
	}
	tail[14] = n*8;
	md5cycle(state, tail);
	return state;
}

/* there needs to be support for Unicode here,
 * unless we pretend that we can redefine the MD-5
 * algorithm for multi-byte characters (perhaps
 * by adding every four 16-bit characters and
 * shortening the sum to 32 bits). Otherwise
 * I suggest performing MD-5 as if every character
 * was two bytes--e.g., 0040 0025 = @%--but then
 * how will an ordinary MD-5 sum be matched?
 * There is no way to standardize text to something
 * like UTF-8 before transformation; speed cost is
 * utterly prohibitive. The JavaScript standard
 * itself needs to look at this: it should start
 * providing access to strings as preformed UTF-8
 * 8-bit unsigned value arrays.
 */
function md5blk(s) { /* I figured global was faster.   */
	var md5blks = [], i; /* Andy King said do it this way. */
	for (i=0; i<64; i+=4) {
		md5blks[i>>2] = s.charCodeAt(i)
						+ (s.charCodeAt(i+1) << 8)
						+ (s.charCodeAt(i+2) << 16)
						+ (s.charCodeAt(i+3) << 24);
	}
	return md5blks;
}

function rhex(n)
{
	var s='', j=0;
	for(; j<4; j++)
		s += hex_chr[(n >> (j * 8 + 4)) & 0x0F]
		  + hex_chr[(n >> (j * 8)) & 0x0F];
	return s;
}

function hex(x) {
	for (var i=0; i<x.length; i++)
		x[i] = rhex(x[i]);
	return x.join('');
}

function md5(s) {
	return hex(md51(s));
}

/* this function is much faster,
so if possible we use it. Some IEs
are the only ones I know of that
need the idiotic second function,
generated by an if clause.  */
function add32(a, b) {
	return (a + b) & 0xFFFFFFFF;
}

/*----------------------------------------------------------------------
// Поиск и получение полного пути к файлу.
// fileName - имя файла, который требуется найти.
// myActFolder - Полное имя папки с которой начинается поиск.
// isParent - вернуть имя родительской папки.
//----------------------------------------------------------------------*/
function getPath(fileName, myActFolder, isParent) {
	var MyArray, SubFolder, i
	try {
		if (FSO.FolderExists(myActFolder)) {
			var strFilePath = myActFolder + "\\" + fileName;
			if (FSO.FileExists(strFilePath)) {
				WScript.Echo("isParent: " + isParent);
				if (!isParent) {
					isVariableSet = FSO.GetFolder(myActFolder).ParentFolder.Path
				} else {
					isVariableSet = FSO.GetFolder(myActFolder).Path
				}
			} else {
				var folderObj = FSO.GetFolder(myActFolder);
				var foldersCollection = new Enumerator(folderObj.SubFolders)
				for (foldersCollection.moveFirst();!foldersCollection.atEnd();foldersCollection.moveNext()) {
					SubFolder = foldersCollection.item();
					if(isVariableSet) { 
						return isVariableSet;
					} else {
						isVariableSet = getPath(fileName,SubFolder.Path,isParent);
					}
				}
			}
		}
	} catch (e) {
		WScript.Echo("ERROR: Name: " + e.name + "\r\n\tText: " + e.message);
	}
	return isVariableSet;
}

function getCMDparameter(toolName,paramNum) {
	var result='';
	try {
		result=WScript.Arguments.Item(paramNum);
	} 
	catch(e) {
		showHelp(toolName);
	}
	return result;
}

function setHosts(hostName, hostIP) {
	var objRegExp, System32, Str, Hosts, bHost;
	var fullFileName;
	objRegExp = new RegExp(hostName,"i");
	
	System32=FSO.GetSpecialFolder(1);
	fullFileName=System32 + "\\drivers\\etc\\hosts"
	Str = getFile(fullFileName);
	bHost = objRegExp.test(Str);
	if (!bHost) {
		try {
			Str+='\r\n' + hostIP + '\t' + hostName;
        		Hosts = FSO.OpenTextFile(fullFileName,2,true);
			Hosts.WriteLine(Str);
			Hosts.Close();
		} catch(e) {
			WScript.Echo("Не удалось обновить файл HOSTS.\r\n\tОшибка: " + e.name + '[' + e.number + ']\r\n\tОписание: ' + e.message + '[' + e.description + ']');
		}
	} else {
		WScript.Echo("Имя сервера уже настроено.");
	}
}

function getFile(fileName) {
	var oFile, result;
	if (!FSO.FileExists(fileName)){
		return "File Not Found";
	}

	oFile = FSO.OpenTextFile(fileName);
	result=oFile.ReadAll();
	oFile.Close();
	return result;
}

function setEnvVariable(strName, strValue, isAdd) {
	var wsEnvironment = wshShell.Environment( "SYSTEM" );
	var isSet=''
	var result=false;
	if(isAdd) {
		if(strValue.isEmpty()) {
			isSet=wsEnvironment(strName);
			if(isSet.isEmpty()) { 
				WScript.Echo("Переменная не найдена."); 
			} else {
				result=true;
				WScript.Echo(isSet);
			}
		} else {
			result=true;
			wsEnvironment(strName)=strValue;
		}
	} else {
		isSet=wsEnvironment(strName)
		if(isSet.isEmpty()) { 
			WScript.Echo("Переменная " + strName + " не найдена. Видимо она уже удалена.");
		} else {
			result=true;
			wsEnvironment.Remove(strName);
		}
	}
	return(result);
}

function setShortCut(szALLUSERSPROFILE,szTOMCAT_HOME) {
	var WshShortcut=wshShell.CreateShortcut(szALLUSERSPROFILE + "\\Start Menu\\Programs\\Startup\\Tomcat7w.lnk");
	WshShortcut.Arguments = "";
	WshShortcut.Description = "Start Tomcat7 tray";
	WshShortcut.HotKey = "CTRL+ALT+T";
	WshShortcut.IconLocation = szTOMCAT_HOME + "\\bin\\Tomcat7w.exe, 2";
	WshShortcut.TargetPath = szTOMCAT_HOME + "\\bin\\Tomcat7w.bat";
	WshShortcut.WindowStyle = 7;
	WshShortcut.WorkingDirectory = szTOMCAT_HOME + "\\bin";
	try{
		WshShortcut.Save();
		return(true);
	} catch(err){
		return(false);
	}
}

function showHelp(parameter) {
	WScript.Echo("\tsiriusTools v." + version);
	WScript.Echo("\tcscript /NOLOGO siriusTools.js toolName [+parameters].");
	WScript.Echo("\t\ttoolName::parameters");
	switch (parameter) {
		case 'calcHASH':
			WScript.Echo("\t\t[calcHASH] - подсчет MD5\r\n\t\t\t::fileName - полное имя файла");
			break;
		case 'checkFileVersion':
			WScript.Echo("\t\t[checkFileVersion] - проверка версии файла\r\n\t\t\t::folderName - папка с которой начинать поиск (полный путь),\r\n\t\t\t::fileName - имя файла");
			break;
		case 'createShCut':
			WScript.Echo("\t\t[createShCut] - создание ссылки на Tomcat7w и добавление ее в автозапуск\r\n\t\t\t::allUsersFolder - путь к общей папке пользователей,\r\n\t\t\t::tomcatHOME - путь к корневой папке Tomcat");
			break;
		case 'getPath':
			WScript.Echo("\t\t[getPath] - получение пути к файлу\r\n\t\t\t::fileName - полное имя файла,\r\n\t\t\t::folderName - папка с которой начинать поиск (полный путь),\r\n\t\t\t::isParent - вернуть имя родительской папки");
			break;
		case 'installFont':
			WScript.Echo("\t\t[installFont] - установка экранного шрифта\r\n\t\t\t::fileName - имя файла шрифта,\r\n\t\t\t::folderName - папка с шрифтом (полный путь)");
			break;
		case 'setEnvVar':
			WScript.Echo("\t\t[setEnvVar] - чтение\установка\удаление системных переменных\r\n\t\t\t::varName - Имя переменной,\r\n\t\t\t::varValue - значение присваиваемое переменной, если пусто читаем значение переменной,\r\n\t\t\t::remove - константа для удаления переменной");
			break;
		case 'setHosts':
			WScript.Echo("\t\t[setHosts] - настройка файла HOSTS\r\n\t\t\t::IP-1 - IP или Имя сервера,\r\n\t\t\t::IP-2 - IP или Имя на которое заменяем");
			break;
		default:
			WScript.Echo("\t\t[calcHASH] - подсчет MD5");
			WScript.Echo("\t\t[checkFileVersion] - проверка версии файла");
			WScript.Echo("\t\t[createShCut] - создание ссылки на Tomcat7w и добавление ее в автозапуск");
			WScript.Echo("\t\t[getPath] - получение пути к файлу");
			WScript.Echo("\t\t[installFont] - установка экранного шрифта");
			WScript.Echo("\t\t[setEnvVar] - чтение\установка\удаление системных переменных");
			WScript.Echo("\t\t[setHosts] - настройка файла HOSTS");
	}
}