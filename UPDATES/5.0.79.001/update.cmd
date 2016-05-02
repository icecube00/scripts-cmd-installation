@echo off
set updateversion=5.0.79.001
@echo UPDATE %updateversion%: Resources update: START
set path="C:\Install\sirius_agent";%path%
call:check_line "%SIRIUS_ATM_PROPERTIES%\sirius-atm.properties" "UPDATE %updateversion%"
if [%linefound%]==[] (
	call:copy_resources
	echo. >>"%SIRIUS_ATM_PROPERTIES%\sirius-atm.properties"
	echo #UPDATE %updateversion%:: Актуализация ресурсов до ЕРИБ 19.0 >>"%SIRIUS_ATM_PROPERTIES%\sirius-atm.properties"
)

@echo UPDATE %updateversion%: Resources update: FINISH
goto:EOF

:check_line
	for /f "tokens=2 delims== " %%a in ('type "%~1"^|find "%~2"') do (
		set linefound="%%~a"
	)
goto:EOF

:copy_resources
	for /f "tokens=2 delims== " %%a in ('type "%SIRIUS_ATM_PROPERTIES%\sirius-atm.properties"^|find "path.resources"') do (
		if not defined pathresources set pathresources=%%~a\services
	)
	for /f "tokens=2 delims== " %%a in ('type "%SIRIUS_ATM_PROPERTIES%\sirius-atm.properties"^|find "path.images"') do (
		if not defined pathresources set pathresources=%%~a
	)
	echo		����室��� �������� ������ � ����� %pathresources%
	rar x newResourcesId.rar -o+ -y -idp -inul "%pathresources%"\ >NUL
goto:EOF