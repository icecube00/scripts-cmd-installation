Option Explicit
Dim isSet, FSO, i, probablePath

Set FSO = CreateObject("Scripting.FileSystemObject")		'������ ����.����

isSet = ""

Select Case WScript.Arguments.Length
	Case 0
		WScript.Echo "���������� ������������ ���������."
	Case 1
		SetEnvVariable WScript.Arguments.Item(0), "", True
	Case 2
		SetEnvVariable WScript.Arguments.Item(0), WScript.Arguments.Item(1), True
	Case Else
		If WScript.Arguments.Item(WScript.Arguments.Length-1)="remove" Then
			SetEnvVariable WScript.Arguments.Item(0), WScript.Arguments.Item(1), False
			If Not isSet="" Then WScript.Echo "���������� ��������� - " & WScript.Arguments.Item(0) & " ���� �������."
		Else
			For i = 1 to WScript.Arguments.Length-1
				probablePath = Trim(probablePath & " " & WScript.Arguments.Item(i))
			Next
			If Not FSO.FolderExists(probablePath) Then WScript.Echo "���������� ���� �� ���������� - " & probablePath
			SetEnvVariable WScript.Arguments.Item(0), probablePath, True
		End If
End Select

Sub SetEnvVariable(strName, strValue, isAdd)
	Dim wshShell,wsEnvironment
	Set wshShell = CreateObject( "WScript.Shell" )
	Set wsEnvironment = wshShell.Environment( "SYSTEM" )
	If isAdd Then
		If strValue="" Then			
			isSet = wsEnvironment(strName)
			If isSet="" Then WScript.Echo "���������� �� �������." Else WScript.Echo isSet
		Else
			wsEnvironment(strName)=strValue
		End If
	Else
		isSet = wsEnvironment(strName)
		If isSet="" Then
			WScript.Echo "���������� �� �������. ������ ��� ��� �������."
		Else
			wsEnvironment.Remove(strName)
		End If
	End If
	Set wsEnvironment = Nothing
	Set wshShell = Nothing
End Sub