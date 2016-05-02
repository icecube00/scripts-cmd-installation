var result,request,reason, Vesrion;
var Duration, totalDuration, median, maxDuration, minDuration;
var i, timerBegin, timerEnd, boundary;
var wasURL, localIP, properties;
var propVersion;

propVersion="Скрипт checkSirius.js 2.02";

totalDuration = 0;
maxDuration = 0;
minDuration = 99999999;

properties = new ActiveXObject("Scripting.Dictionary");

var sirius_atm_properties = "C:/Program Files/Apache Software Foundation/Tomcat 7.0/webapps/sirius-atm.properties";

timerBegin = Timer();
reason = "штатно.";

if (WScript.Arguments.Length < 3) { 
	if (WScript.Arguments.Length > 0) {
		if (WScript.Arguments.Item(0)=="Version") {
			WScript.Echo (propVersion);
		} else {
			WScript.Echo ("Отсутсвуют обязательные параметры.");
		}
	}
} else {
	WScript.Arguments.Item(2)==""?localIP="127.0.0.1":localIP=WScript.Arguments.Item(2);

	var tomcatURL = "http://" + localIP + ":8080/sirius-atm/";
	readSettings(sirius_atm_properties)

	wasURL = properties("server")

	WScript.Echo ("Time; Initiator; Script Duration; Current Duration; Current Count; Median duration; Maximum duration; Minimum duration; Total Duration");
	switch (WScript.Arguments.item(1)) {
		case "tomcat":
			//Инициализируем приложение.
			result = HttpRequest(tomcatURL,"","urlencoded","GET");
			Vesrion = siriusHTTPping (WScript.Arguments.Item(0), tomcatURL + "start", "urlencoded", "Tomcat");
			break;
		case "direct":
			Vesrion = siriusHTTPping (WScript.Arguments.Item(0), wasURL, "boundary", "Direct");
			break;
		default:
			WScript.Echo ("Default. argument: " + WScript.Arguments.item(1));
	}
	WScript.Echo (Vesrion);
}

function HttpRequest(URL, FormData, typeData, requestType) {
	var newhttp, Begin;
	newhttp = getXMLHttp();
	Begin = Timer();
	newhttp.open(requestType, URL, false);
	switch (typeData) {
		case "boundary":
			newhttp.setRequestHeader("Content-Type", "multipart/form-data; boundary=" + boundary + "; charset=UTF-8");
			break;
		case "urlencoded":
			newhttp.setRequestHeader("Content-Type", "application/x-www-form-urlencoded; charset=UTF-8");
			break;
	}
	newhttp.send (FormData);
	Duration = Timer() - Begin;
	return newhttp;
}

function Timer(ms) {
	var tresult;
	var d = new Date();
	var milliseconds = d.getTime();
	var time = ('0' + d.getHours()).slice(-2) + ':' + ('0' + d.getMinutes()).slice(-2) + ':' + ('0' + d.getSeconds()).slice(-2) + ',' + ('00' + d.getMilliseconds()).slice(-3);
	ms=!ms ? tresult=milliseconds: tresult=time;
	return tresult;
}

function getXMLHttp() {
	var xmlHttp
	try {
		xmlHttp = new ActiveXObject("MSXML2.ServerXMLHTTP.3.0");
	} catch(e) {
		try {
			xmlHttp = new ActiveXObject("Microsoft.XMLHTTP");
		} catch(E) {
			xmlHttp = false;
		}
	}
	//For Mozila, Opera and WebKit Browsers
	if (!xmlHttp && typeOf(XMLHttpRequest) !='undefined') {
		xmlHttp = new XMLHttpRequest();
	}
	xmlHttp.setOption(2, 13056);
	return xmlHttp;
}

function LenB(str) {
	var m = encodeURIComponent(str).match(/%[89ABab]/g);
	return str.length + (m?m.length:0);
}

function setFormData(arrData, typeData) {
	var body
	switch (typeData) {
		case "boundary":
			body = ['\r\n']
			boundary = '' + String(Math.random()).slice(2) + '';
			var boundaryMiddle = '--' + boundary + '\r\n';
			var boundaryLast = '--' + boundary + '--\r\n';

			for (var key in arrData) {
				body.push('Content-Disposition: form-data; name="' + key + '"\r\nContent-Type: text/plain; charset=UTF-8\r\nContent-Transfer-Encoding: 8bit\r\n\r\n' + arrData[key] + '\r\n');
			}
			body = body.join(boundaryMiddle) + boundaryLast;
			break;
		case "urlencoded":
			body = ['?']
			for (var key in arrData) {
				body.push(key + '=' + encodeURIComponent(arrData[key]));
			}
			body = body.join('&');
			break;
		default:
			body = false;
	}
	return body;
}

function readSettings(filePath) {
	var fso = new ActiveXObject("Scripting.FileSystemObject");
	var f = fso.GetFile(filePath);
	var s_prop = f.OpenAsTextStream(1, -2);
	var sirius_prop = [''];
	while (!s_prop.AtEndOfStream) {
		var txt = trim(s_prop.ReadLine());
		if (txt.charAt(0)!="#") {
        		var temp = txt.split("=");
			if (trim(temp[1])!="") {
				if (!properties.Exists(trim(temp[0]))) properties.add (trim(temp[0]),trim(temp[1]));
				if (trim(temp[0])=="path.config.ndc") readSettings(trim(temp[1]));
			}
		}
	}
	return properties;
}

function trim(str, charlist) {
	str = !str ? '':str;
	charlist = !charlist ? ' \xA0' : charlist.replace(/([\[\]\(\)\.\?\/\*\{\}\+\$\^\:])/g, '\$1');
	var re = new RegExp('^[' + charlist + ']+|[' + charlist + ']+$', 'g');
	return str.replace(re, '');
}

function siriusHTTPping(tryCount, strURL, reqType, Initator) {
	var data = {
		cmd: 'CMD_START',
		pan: 'TEST_PAN',
		terminal: properties('AtmNumber'),
		token: 'SIRIUS',
		protocol_version: '3',
		opcode: 'COULD_NOT_GET_OPCODE',
		activeDevicesMask: 'COULD_NOT_GET_ACTIVE_DEVICES_MASK',
		amount: 'COULD_NOT_GET_AMOUNT',
		b: 'COULD_NOT_GET_B',
		c: 'COULD_NOT_GET_C',
		currLangOffset: 'COULD_NOT_GET_CURRENT_LANG_OFFSET',
		luno: properties('LUNO'),
		ndc_config_id: properties('ConfigID'),
		devices: '0'
	}
	for (i=0;i<tryCount;i++) {
		result = HttpRequest(strURL,setFormData(data, reqType),reqType,"POST");
		request = LenB(result.responseText);
		totalDuration = totalDuration+Duration;
		if (Duration > maxDuration) maxDuration = Duration;
		if (Duration < minDuration) minDuration = Duration;
		median = totalDuration/(i+1);
		timerEnd = Timer() - timerBegin;
		WScript.Echo (Timer('ms') + "; " + Initator + "; " + timerEnd + "; " + Duration + "; " + i + "; " + median + "; " + maxDuration + "; " + minDuration+ "; " + totalDuration);
		if (timerEnd > 60000) { 
			reason = "по таймауту на " + i + " попытке.";
			break;
		}
	}
	if (tryCount>1) {
		return(result.responseText);
	} else {
		return("Длительность работы скрипта: " + timerEnd + " мс. Завершен " + reason + " Среднее время связи с сервером СИРИУС: " + median + " сек." + " Скорость: " + request/median + " байт/сек" + " Максимальное время связи: " + maxDuration + " мс." + " Минимальное время связи: " + minDuration + " мс.");
	}
}