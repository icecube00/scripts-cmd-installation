Option Explicit

Dim FSO, WshShell

Set FSO = CreateObject("Scripting.FileSystemObject")		'Объект файл.сист
Set WshShell = CreateObject("WScript.Shell")

Select Case WScript.Arguments.Length
	Case 0
		WScript.Echo "Отсутсвуют обязательные параметры."
	Case 1
		setHosts WScript.Arguments.Item(0), "127.0.0.1"
	Case 2
		setHosts WScript.Arguments.Item(0), WScript.Arguments.Item(1)
	Case Else
		WScript.Echo "Некорректный синтаксис."
End Select

Sub setHosts(hostName, hostIP)
	Dim objRegExp, System32, Str, Hosts, objMatches
	Set objRegExp = CreateObject("VBScript.RegExp")
	System32=FSO.GetSpecialFolder(1)
	objRegExp.IgnoreCase = True
	objRegExp.Pattern = hostName
	Str = GetFile(System32 & "\drivers\etc\hosts")
	Set objMatches = objRegExp.Execute(Str)
	If (objMatches.count=0) then
		Str = Str & vbCrLf & hostIP & VbTab & hostName
		Set Hosts = FSO.OpenTextFile(System32 & "\drivers\etc\hosts",2,TRUE)
		Hosts.WriteLine Str
		Hosts.Close
	Else
		WScript.Echo "Имя сервера уже настроено."
	End if
End Sub

Function GetFile(ByVal FileName)
	On Error Resume Next
	Dim File
	If Not FSO.FileExists(FileName) Then
		GetFile = ""
		Exit Function
	End If
	Set File = FSO.OpenTextFile(FileName)
	GetFile = File.ReadAll
	File.Close
End Function
