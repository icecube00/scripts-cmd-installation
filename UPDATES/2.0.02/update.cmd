call:check_line "%SIRIUS_ATM_PROPERTIES%\sirius-atm.properties" "UPDATE 2.0.02"
if [%linefound%]==[] (
	del C:\resources\services\*.jpg /f /q
	echo. >>"%SIRIUS_ATM_PROPERTIES%\sirius-atm.properties"
	echo #UPDATE 2.0.02:: Удаление ресурсов БД >>"%SIRIUS_ATM_PROPERTIES%\sirius-atm.properties"
)
goto:EOF

:check_line
	for /f "tokens=2 delims== " %%a in ('type "%~1"^|find "%~2"') do (
		set linefound="%%~a"
	)
goto:EOF

