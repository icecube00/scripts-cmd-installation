var wbemFlagReturnImmediately = 0x10;
var wbemFlagForwardOnly = 0x20;
var objWMIService = GetObject("winmgmts:\\\\.\\root\\CIMV2");
var propVersion='1.00';
var param0='', param1='', param2='', param3='', param4='', param5='';
var wherestatement='';

Object.prototype.prototypeOf = function(){
    if(this === undefined || this === null) throw new TypeError('"Object.prototype.prototypeOf" is NULL or not defined');
    var result='';
    var funcRegEx=/function (.{1,})\(/;
    var results=(funcRegEx).exec((this).constructor.toString());
    if (results.length>1) result=results[1];
    return result;
};

//Объявление прототипа isEmpty для строк
if (!String.prototype.isEmpty) {
    String.prototype.isEmpty=function(){
        if(this === undefined || this === null) 
            throw new TypeError('"String.prototype.isEmpty" is NULL or not defined');
        var length = this.length;
        return (length<1);
    };
}

if (!String.prototype.contains) {
    String.prototype.contains = function (searchString) {
        if (this === undefined || this === null)
            throw new TypeError('"String.prototype.contains" is NULL or not defined');
        return (this.indexOf(searchString) !== -1);
    };
}

if (WScript.Arguments.Length > 0) {
    if (WScript.Arguments.Length > 1) param1 = WScript.Arguments.Item(1);
    if (WScript.Arguments.Length > 2) param2 = WScript.Arguments.Item(2);
    if (WScript.Arguments.Length > 3) param3 = WScript.Arguments.Item(3);
    if (WScript.Arguments.Length > 4) param4 = WScript.Arguments.Item(4);
    if (WScript.Arguments.Length > 5) param5 = WScript.Arguments.Item(5);
    var delimWhereSt='=';
    var openWhereSt='="';
    var closeWhereSt='"';
    if (param1==='where') {
        if(param2.contains(' in ')) {
            delimWhereSt=' in ';
            openWhereSt=' in "';
            closeWhereSt='"';
        } 
        wherestatement = param1 + ' ' + param2.split(delimWhereSt)[0] + openWhereSt + trim(param2.split(delimWhereSt)[1],"'") + closeWhereSt;
        param1=param3;
        param2=param4;
    };
    if (param2==='where') {
        if(param3.contains(' in ')) {
            delimWhereSt=' in ';
            openWhereSt=' in "';
            closeWhereSt='"';
        } 
        wherestatement = param2 + ' ' + param3.split(delimWhereSt)[0] + openWhereSt + trim(param3.split(delimWhereSt)[1],"'") + closeWhereSt;
        param2=param4;
        param3=param5;
    };
    switch (WScript.Arguments.Item(0)) {
        case 'os':
            param0="Win32_OperatingSystem";
            if(!wherestatement.isEmpty()) {
                param0="Win32_OperatingSystem " + wherestatement;
            }
            getWMIInfo(param0,param1,param2);
            break;
        case 'desktopmonitor':
            param0="WIN32_DESKTOPMONITOR";
            if(!wherestatement.isEmpty()) {
                param0="WIN32_DESKTOPMONITOR " + wherestatement;
            }
            getWMIInfo(param0,param1,param2);
            break;
        case 'path':
            param0=param1;
            if(!wherestatement.isEmpty()) {
                param0=param1 + " " + wherestatement;
            }
            //WScript.Echo('0: ' + param0 + '\r\n1: ' + param1 + '\r\n2: ' + param2 + '\r\n3: ' + param3 + '\r\n4: ' + param4 + '\r\n5: ' + param5);
            getWMIInfo(param0, param2, param3);
            break;
        case 'datafile':
            param0="CIM_DataFile";
            if(!wherestatement.isEmpty()) {
                param0="CIM_DataFile " + wherestatement;
            }
            getWMIInfo(param0,param1,param2);
            break;
        case 'nicconfig':
            param0="Win32_NetworkAdapterConfiguration";
            if(!wherestatement.isEmpty()) {
                param0="Win32_NetworkAdapterConfiguration " + wherestatement;
            }
            getWMIInfo(param0,param1,param2);
            break;
        default:
            WScript.Echo("WMIC Emulation: v."+propVersion);
            WScript.Echo('0: ' + WScript.Arguments.Item(0) + '\t1: ' + param1 + '\t2: ' + param2 + '\t3: ' + param3 + '\t4: ' + param4 + '\t5: ' + param5);
    }
} else {
    WScript.Echo("WMIC Emulation: v."+propVersion);
}

function getWMIInfo(wmiClass,param,getParam) {
    //WScript.Echo('wmiClass: ' + wmiClass + '\tparam: ' + param + '\tgetParam: ' + getParam);
    var colItems = objWMIService.ExecQuery("SELECT * FROM " + wmiClass + "", "WQL",wbemFlagReturnImmediately | wbemFlagForwardOnly);
    var enumItems = new Enumerator(colItems);
    if(getParam.split(',').length>1 && param.toLowerCase()==='get') WScript.Echo(getParam.split(',').join('\t'));
    for (; !enumItems.atEnd(); enumItems.moveNext()) {
        var objItem = enumItems.item();
        switch (param.toLowerCase()) {
            case 'totalvisiblememorysize':
                WScript.Echo(objItem.TotalVisibleMemorySize);
                break;
            case 'oslanguage':
                WScript.Echo(objItem.OSLanguage);
                break;
            case 'localdatetime':
                WScript.Echo(objItem.LocalDateTime);
                break;
            case 'get':
                getParamValue(objItem,getParam);
                break;
            case 'set':
                setParamValue(objItem,getParam);
                break;
            default:
                WScript.Echo(512000);
        }
    }
}

function getParamValue(wmiObjItem,paramName) {
    var result=[];
    if (!paramName.isEmpty()) {
        var paramArray=paramName.split(',');
        var lengthParam=paramArray.length;
        for (var i=0;i<lengthParam;i++) {
            var resultString='' + eval('wmiObjItem.' + paramArray[i])+ '';
            if(resultString && !resultString.isEmpty()) result.push(resultString);
        }
    }
    if(result.length>0) WScript.Echo(result.join('\t'));
}

function setParamValue(wmiObjItem,paramName,paramValue) {
    var result ='';
    if (!paramName.isEmpty()) {
        var oResult = eval('wmiObjItem.' + paramName + '=' + paramValue);
        result=oResult.toString();
    }
    WScript.Echo(result);
}

function getMaxResolution() {
    var colItems = objWMIService.ExecQuery("SELECT * FROM CIM_VideoControllerResolution", "WQL", wbemFlagReturnImmediately | wbemFlagForwardOnly);
    var enumItems = new Enumerator(colItems);
    var resolutionCollection = [];
    
    for (; !enumItems.atEnd(); enumItems.moveNext()) {
        var objItem = enumItems.item();
        var rating = ((objItem.VerticalResolution * objItem.HorizontalResolution)+objItem.NumberOfColors);
        var obj={};
        obj["rating"]=rating;
        obj["resolution"]=objItem.SettingID;
        resolutionCollection.push(obj);
    }
    var a = resolutionCollection.sort(function(x,y){return (x.rating-y.rating);}).pop();
    WScript.Echo (a.resolution);
}

function byKey(a,b) {
    var keyA=parseInt(a.rating);
    var keyB=parseInt(b.rating);
    if (keyA<keyB) return -1;
    if (keyA>keyB) return 1;
    return 0;
}

function trim(str, charlist) {
    str = !str ? '':str;
    charlist = !charlist ? ' \xA0' : charlist.replace(/([\[\]\(\)\.\?\/\*\{\}\+\$\^\:])/g, '\$1');
    var re = new RegExp('^[' + charlist + ']+|[' + charlist + ']+$', 'g');
    return str.replace(re, '');
}