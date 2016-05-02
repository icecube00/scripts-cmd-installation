xcopy /Q /H /E /Y "%TOMCAT_HOME%\webapps\sirius-atm\WEB-INF\templates\*.*" "%TOMCAT_HOME%\templates\"
xcopy /C /R /Y "update\init.html" "%TOMCAT_HOME%\templates\"
call:check_line "%SIRIUS_ATM_PROPERTIES%\sirius-atm.properties" "C:/Program Files/Apache Software Foundation/Tomcat 7.0/templates"
if [%linefound%]==[] (
	echo. >>"%SIRIUS_ATM_PROPERTIES%\sirius-atm.properties"
	echo path.templates = C:/Program Files/Apache Software Foundation/Tomcat 7.0/templates >>"%SIRIUS_ATM_PROPERTIES%\sirius-atm.properties"
	echo #UPDATE 2.0.01:: Перемещение шаблонов >>"%SIRIUS_ATM_PROPERTIES%\sirius-atm.properties"
)
goto:EOF

:check_line
	for /f "tokens=2 delims== " %%a in ('type "%~1"^|find "%~2"') do (
		set linefound="%%~a"
	)
goto:EOF
