Option Explicit
Dim gotIpAddress

Select Case WScript.Arguments.Length
	Case 0
		WScript.Echo "Отсутсвуют обязательные параметры."
	Case 1
		gotIpAddress = SeparateField(WScript.Arguments.Item(0),"addr="," mask=")
		setNewDNS gotIpAddress, "127.0.0.1"
		WScript.Echo "setNewDNS " & gotIpAddress & ", 127.0.0.1."
	Case 2
		gotIpAddress = SeparateField(WScript.Arguments.Item(0),"addr="," mask=")
		setNewDNS gotIpAddress, WScript.Arguments.Item(1)
	Case Else
		WScript.Echo "Неверное количество параметров."
End Select

Sub setNewDNS(localIP, DNSServer)
	Dim strComputer, NewDnsServerList, OldDnsServerList
	Dim arrDNSServerSearchOrder, result
	Dim objWMIService, colItems, objItem
	
	Const wbemFlagReturnImmediately = &h10
	Const wbemFlagForwardOnly = &h20
	strComputer="."
	
	localIP=ClearString(localIP)
	
	Set objWMIService = GetObject("winmgmts:\\" & strComputer & "\root\CIMV2")
	Set colItems = objWMIService.ExecQuery("SELECT * FROM Win32_NetworkAdapterConfiguration where IPEnabled=true", "WQL", wbemFlagReturnImmediately + wbemFlagForwardOnly)
	
	For Each objItem In colItems
		If objItem.IPAddress(0)=localIP Then
			If IsArray(objItem.DNSServerSearchOrder) Then 
				OldDnsServerList = Join(objItem.DNSServerSearchOrder, ";")
			Else
				OldDnsServerList = ""
			End If
			If InStr(OldDnsServerList,DNSServer) > 0 Then 
				WScript.Echo "Старый DNSServerSearchOrder уже содержит в себе loopback адрес - " & OldDnsServerList
				result = -1
			Else
				If Len(OldDnsServerList) > 6 Then 
					NewDnsServerList = OldDnsServerList & ";" & DNSServer
				Else
					NewDnsServerList = DNSServer
				End If
				WScript.Echo "Новый DNSServerSearchOrder - " & NewDnsServerList
				arrDNSServerSearchOrder = Split(NewDnsServerList,";")
				objItem.SetDNSServerSearchOrder(Array())
				result = objItem.SetDNSServerSearchOrder(arrDNSServerSearchOrder)
			End If
			WScript.Echo "Результат настройки DNS: " & result
		End If
	Next
End Sub

Function ClearString(string2Clear)
	string2Clear = Replace(string2Clear,vbCr,"")
	string2Clear = Replace(string2Clear,vbLf,"")
	string2Clear = Replace(string2Clear,vbTab," ")
	string2Clear = Replace(string2Clear,"  "," ")
	ClearString=string2Clear
End Function

'----------------------------------------------------------------------
'Выделение части текста
'----------------------------------------------------------------------
Function SeparateField(ByVal sFrom, ByVal sStart, ByVal sEnd)
	Dim PosB, PosE
	PosB = InStr(1, sFrom, sStart, 1)
	If PosB > 0 Then
	PosB = PosB + Len(sStart)
		PosE = InStr(PosB, sFrom, sEnd, 1)
		If PosE = 0 Then PosE = InStr(PosB, sFrom, vbCrLf, 1)
		If PosE = 0 Then PosE = Len(sFrom) + 1
		SeparateField = Mid(sFrom, PosB, PosE - PosB)
	End If
End Function
