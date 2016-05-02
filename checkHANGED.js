if (WScript.Arguments.Length < 1) {
 WScript.Echo("Отсутсвуют обязательные параметры.");
}
else {
 var reason=WScript.Arguments.Item(0);
 var wmiServices=GetObject("winmgmts:\\\\.\\root\\default");
 var wmiSink = WScript.CreateObject("WbemScripting.SWbemSink", "SINK_");
 var wshShell = new ActiveXObject("WScript.Shell");
 var stillInService=true;
 
 wmiServices.ExecNotificationQueryAsync (wmiSink, "SELECT * FROM RegistryValueChangeEvent WHERE Hive='HKEY_LOCAL_MACHINE' And KeyPath='SOFTWARE\\\\SCS\\\\DEV\\\\ATM\\\\Status' And ValueName = 'AtmMode'");

 while (stillInService) WScript.Sleep(5000);
}
 
function SINK_OnObjectReady(wmiObject, wmiAsyncContext) {
 checkInServiceState(reason);
}

function checkInServiceState(reason) {
 var atmMode = wshShell.RegRead("HKLM\\SOFTWARE\\SCS\\DEV\\ATM\\Status\\AtmMode")
 switch (atmMode) {
  case 1:
   stillInService=false;
   resetATM(reason);
   break;
  case 2:
   stillInService=false;
   resetATM(reason);
   break;
  case 5:
   stillInService=false;
   resetATM(reason);
   break;
  default:
   stillInService=true;
   break;
 }
}

function resetATM(reason){
 d = new Date();
 wshShell.RegWrite("HKEY_CURRENT_USER\Sirius\Restarted\Date",d.toLocaleString(),"REG_SZ");
 wshShell.RegWrite("HKEY_CURRENT_USER\Sirius\Restarted\Reason",reason,"REG_SZ");
 wshShell.Run("shutdown.exe -r -t 00 -f");
}