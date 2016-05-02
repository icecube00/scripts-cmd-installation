Option Explicit
Dim FSO
Set FSO = CreateObject("Scripting.FileSystemObject")		'Объект файл.сист

If WScript.Arguments.Length < 2 Then 
	WScript.Echo "Отсутсвуют обязательные параметры."
Else
	If FSO.FolderExists(WScript.Arguments.Item(0) & "\Start Menu\Programs\Startup") and FSO.FolderExists(WScript.Arguments.Item(1) & "\bin") Then
		setShortCut WScript.Arguments.Item(0), WScript.Arguments.Item(1)
		Wscript.Echo "Создана новая ссылка на файл."
	Else
		Wscript.Echo "Не найдена папка для создания ссылки." & vbCrLf & _
			 WScript.Arguments.Item(0) & "\Start Menu\Programs\Startup" & " = " & FSO.FolderExists(WScript.Arguments.Item(0) & "\Start Menu\Programs\Startup") & vbCrLf & _
			 WScript.Arguments.Item(1) & "\bin" & " = " & FSO.FolderExists(WScript.Arguments.Item(1) & "\bin")
        End If
End If

Sub setShortCut(szALLUSERSPROFILE,szTOMCAT_HOME)
	Dim WshShell, WshShortcut
	Set WshShell = CreateObject("WScript.Shell")
	Set WshShortcut = WshShell.CreateShortcut(szALLUSERSPROFILE & "\Start Menu\Programs\Startup\Tomcat7w.lnk")
	WshShortcut.Arguments = ""
	WshShortcut.Description = "Start Tomcat7 tray"
	WshShortcut.HotKey = "CTRL+ALT+T"
	WshShortcut.IconLocation = szTOMCAT_HOME & "\bin\Tomcat7w.exe, 2"
	WshShortcut.TargetPath = szTOMCAT_HOME & "\bin\Tomcat7w.bat"
	WshShortcut.WindowStyle = 7
	WshShortcut.WorkingDirectory = szTOMCAT_HOME & "\bin"
	WshShortcut.Save
End Sub	


