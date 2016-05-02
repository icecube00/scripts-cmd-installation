Option Explicit

Dim Vesrion'As String
Dim FSO'As Object

Set FSO = CreateObject("Scripting.FileSystemObject")		'Объект файл.сист

If WScript.Arguments.Length < 1 Then 
	WScript.Echo "Отсутсвуют обязательные параметры."
Else
	Vesrion = GetFileVersion (WScript.Arguments.Item(0))
	Wscript.Echo Vesrion
End If

Function GetFileVersion(pathToFile)
	Dim fileversion
	fileversion ="0.0.0.0"
	If FSO.FileExists(pathToFile) Then
		fileversion = FSO.GetFileVersion(pathToFile)
	End If
	GetFileVersion = fileversion
End Function