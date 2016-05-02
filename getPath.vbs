Option Explicit
Dim FSO
Set FSO = CreateObject("Scripting.FileSystemObject")		'Объект файл.сист

Dim isVariableSet, pathReturned
isVariableSet = "False"
If WScript.Arguments.Length < 3 Then 
	WScript.Echo "Отсутсвуют обязательные параметры."
Else
	pathReturned = SetVariable(WScript.Arguments.Item(0), WScript.Arguments.Item(1), WScript.Arguments.Item(2))
	Wscript.Echo pathReturned
End If

'----------------------------------------------------------------------
'Инициализация переменных
'----------------------------------------------------------------------
Function SetVariable(ByVal FileName, ByVal myActFolder, ByVal isParent)
	Dim MyArray, SubFolder, i
	On Error Resume Next
	If FSO.FolderExists(myActFolder) Then
		WScript.Echo "FOLDER " & myActFolder & " EXIST"
		If FSO.FileExists(myActFolder & "\" & FileName) Then
			WScript.Echo "FILE " & FileName & " EXIST"
			WScript.Echo isParent
			If isParent then 
				isVariableSet = FSO.GetFolder(myActFolder).ParentFolder.Path
			Else
				isVariableSet = FSO.GetFolder(myActFolder).Path
			End If
		Else
			For Each SubFolder in FSO.GetFolder(myActFolder).SubFolders
				If Not isVariableSet="False" Then
					Exit For
				Else
					SetVariable Filename,SubFolder.Path,isParent
				End If
			Next
		End If
	End If
	SetVariable = isVariableSet
End Function
