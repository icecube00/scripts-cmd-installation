Option Explicit
Dim Dismiss

If WScript.Arguments.Length > 0 Then 
	Dismiss = MsgBox (WScript.Arguments.Item(0), _
			  4+48+256, _
			  "����������?")
	If Dismiss = 7 Then 
		WScript.Echo "stop"
	Else
		WScript.Echo "_go_"
	End If
Else
	WScript.Echo "����������� ������������ ���������."
End If