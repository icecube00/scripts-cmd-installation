Option Explicit
Dim result,request,reason, Vesrion
Dim Duration, totalDuration, median, maxDuration, minDuration
Dim i, timerBegin, timerEnd

totalDuration = 0
maxDuration = 0
minDuration = 99999999

timerBegin = Timer
reason = "������."

If WScript.Arguments.Length < 2 Then 
	WScript.Echo "���������� ������������ ���������."
Else
	Select Case WScript.Arguments.Item(1)
		Case "tomcat"
			'�������������� ����������.
			Set result = HttpRequest("http://localhost:8080/sirius-atm/","","","GET")
			Vesrion = siriusHTTPping (WScript.Arguments.Item(0))
			Wscript.Echo Vesrion
		Case "direct"
			Vesrion = serverHTTPping (WScript.Arguments.Item(0))
			Wscript.Echo Vesrion			
	End Select
End If

Function siriusHTTPping(tryCount)
	Dim return
	Wscript.Echo "�������� ����� � �������� ������ ����� TOMCAT. ����������� �������: " & tryCount & "."
	For i = 1 to tryCount
		Set result = HttpRequest("http://localhost:8080/sirius-atm/start?devices=COULD_NOT_GET_ACTIVE_DEVICES_MASK&pan=TEST_PAN","","","GET")
		request = 520

		totalDuration = totalDuration+Duration
		If Duration > maxDuration Then maxDuration = Duration
		If Duration < minDuration Then minDuration = Duration
		median = totalDuration/i
'		If tryCount=1 Then
			If (result.status=200) AND (InStr(result.responseText,"atm_print") > 0) Then 
				Wscript.Echo "SUCCESS: ����� � �������� ������ ������� �����������. ����������� �����: " & Duration & " ���."
			Else
				Wscript.Echo "ERROR: ����� � �������� ������ �� �����������. ����������� �����: " & Duration & " ���."
			End If
'		End If
		timerEnd = Timer - timerBegin
		If timerEnd > 60 Then 
			reason = "�� �������� �� " & i & " �������."
			
			Exit For
		End If
	Next
	If return = "" Then
		return = "������������ ������ �������: " & timerEnd & " ���. �������� " & reason & _
		" ������� ����� ����� � �������� ������: " & median & " ���." & _
		" ��������: " & request/median & " ����/���" & _
		" ������������ ����� �����: " & maxDuration & " ���." & _
		" ����������� ����� �����: " & minDuration & " ���."
	End If
	siriusHTTPping=return
End Function

Function serverHTTPping(tryCount)
	Dim return
	Wscript.Echo "�������� ����� � �������� ������ ��������. ����������� �������: " & tryCount & "."
	For i = 1 to tryCount
		Set result = HttpRequest("https://10.67.254.104/Gate/TagGate/v1_1","","","POST")
		request = LenB(result.responseText)

		totalDuration = totalDuration+Duration
		If Duration > maxDuration Then maxDuration = Duration
		If Duration < minDuration Then minDuration = Duration
		median = totalDuration/i
'		If tryCount=1 Then
			If (result.status = 200) Then 
				Wscript.Echo "SUCCESS: ����� � �������� ������ ������� �����������. ����������� �����: " & Duration & " ���."
			Else
				Wscript.Echo "ERROR: ����� � �������� ������ �� �����������. ����������� �����: " & Duration & " ���."
			End If
			Wscript.Echo "������ ������: " & request & " ����."
'		End If
		timerEnd = Timer - timerBegin
		If timerEnd > 60 Then 
			reason = "�� �������� �� " & i & " �������."
			Exit For
		End If
	Next
	If return = "" Then
		return = "������������ ������ �������: " & timerEnd & " ���. �������� " & reason & _
		" ������� ����� ����� � �������� ������: " & median & " ���." & _
		" ��������: " & request/median & " ����/���" & _
		" ������������ ����� �����: " & maxDuration & " ���." & _
		" ����������� ����� �����: " & minDuration & " ���."
	End If
	serverHTTPping=return
End Function

Function HttpRequest(URL, FormData, Boundary, requestType)
	Dim newhttp, Begin
	'Set newhttp = CreateObject("WinHttp.WinHttprequest.5")
	Set newhttp = CreateObject("MSXML2.XMLHTTP")
	If IsObject(newhttp) Then
		Begin = Timer
		newhttp.open requestType, URL, False
		newhttp.setRequestHeader "Content-Type", "multipart/form-data; boundary=" & Boundary & "; charset=UTF-8"
		newhttp.send '(FormData)
		Duration = Timer - Begin
		Set HttpRequest = newhttp
	End If
End Function