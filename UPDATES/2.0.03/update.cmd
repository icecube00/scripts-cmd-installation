@echo off
@echo UPDATE 2.0.03: Resources update: START
call:check_line "%SIRIUS_ATM_PROPERTIES%\sirius-atm.properties" "UPDATE 2.0.03"
if [%linefound%]==[] (
	call del C:\resources\services\*.jpg /f /q
	call:copy_resources
	echo. >>"%SIRIUS_ATM_PROPERTIES%\sirius-atm.properties"
	echo #UPDATE 2.0.03:: ÐžÐ±Ð½Ð¾Ð²Ð»ÐµÐ½Ð¸Ðµ Ñ€ÐµÑÑƒÑ€ÑÐ¾Ð² Ð‘Ð” >>"%SIRIUS_ATM_PROPERTIES%\sirius-atm.properties"
)

@echo UPDATE 2.0.03: Resources update: FINISH
goto:EOF

:check_line
	for /f "tokens=2 delims== " %%a in ('type "%~1"^|find "%~2"') do (
		set linefound="%%~a"
	)
goto:EOF

:copy_resources
	for /f "tokens=2 delims== " %%a in ('type "%SIRIUS_ATM_PROPERTIES%\sirius-atm.properties"^|find "path.resources"') do (
		set pathresources=%%~a
	)
	echo		¥®¡å®¤¨¬® ¯®«®¦¨âì à¥áãàáë ¢ ¯ ¯ªã %pathresources%
	rar x newResourcesId.rar -idp "%pathresources%\services"\ >NUL
goto:EOF