//'----------------------------------------------------------------------
//'Установка экранных шрифтов
//'----------------------------------------------------------------------
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

if (WScript.Arguments.Length < 2) {
	WScript.Echo("ERROR: Отсутсвуют обязательные параметры.")
} else {
	var strFileName = WScript.Arguments.Item(0).toString();
	var strFolderName =  WScript.Arguments.Item(1).toString();
	var FSO = new ActiveXObject("Scripting.FileSystemObject");
	installFonts(strFileName, strFolderName);
}

function installFonts(strFile, strFolder) {
	var objShell, destFolder, fromFolder, oFile;

	var isBatchInstall;
		 
	if (strFile.indexOf("*")>-1) isBatchInstall = true;
	var FONTS = 0x14;
	
	objShell = new ActiveXObject("Shell.Application");
	var wshShell = WScript.CreateObject("WScript.Shell");
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
