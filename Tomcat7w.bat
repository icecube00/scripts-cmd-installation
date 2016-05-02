@echo off

 for /f "tokens=1-4 delims=. " %%a in ('echo %DATE:/=.%') do (
	If [%%d]==[] (
		set YEAR=%%c
		set MONTH=%%b
		set DAY=%%a
		set RegSettings=True
	) else (
		set YEAR=%%d
		set MONTH=%%b
		set DAY=%%c
		set RegSettings=False
	)
 )

 Set OUTPUT="%TOMCAT_HOME%\%YEAR%_%MONTH%_%DAY%_TomcatTray_Starter.log"
 if [%STDOUT_REDIRECTED%]==[] (
	set STDOUT_REDIRECTED=yes
	cls
	cmd.exe /c %0 %* >%OUTPUT% 2>&1
	exit /b %ERRORLEVEL%
 )

 call:writetolog "*******************************************************"

 If Exist C:\install\sirius_agent\update.cmd (
	call:writetolog "	Исполняется файл update.cmd."
	net stop Tomcat7 > NUL 2>&1
	call C:\install\sirius_agent\update.cmd
	call:renVers C:\install\sirius_agent\ update.cmd 0
 )

set stopwaiting=0
:checkTomcat
 net start|find /I "Tomcat7"
 If [%errorlevel%]==[0] (
	call:writetolog "	Сервис Tomcat уже запущен."
	call:trayIcon
 ) else (
	if not[waiting]==[true] call:writetolog "	Сервис Tomcat еще не запущен."
	net start Tomcat7|find /I "Tomcat7"
	If not [%errorlevel%]==[0] (
		call:writetolog "		Ожидаем 5 сек. и проверяем повторно."
		call:wait 5
		set waiting=true
		if %stopwaiting% GEQ 50 ( 
			goto:afterCheckTomcat
		) else (
			call:stopWaiting %stopwaiting%
		)
		goto:checkTomcat
	)
	call:trayIcon
 )

:afterCheckTomcat
:: call:writetolog "-------------------------------------------------------"
:: Сюда возможно нужно добавить проверку TellMe\не TellMe
:: call:writetolog "Запуск TellMe"
:: pushd C:\SCS\ATM_H
:: 	start ATM_H.exe
:: popd

 call:writetolog "	Ожидаем развертывания приложения SIRIUS (30 секунд)"
 call:wait 30
 call:writetolog "-------------------------------------------------------"
 call:writetolog "	Проверка доступности сервера СИРИУС."
 for /f "usebackq tokens=*" %%i in (`cscript /NOLOGO C:\install\sirius_agent\checkSirius.vbs 1`) do set checkSiriusResult=%%i
 call:writetolog "		%checkSiriusResult%"
 call:writetolog "*******************************************************"
 call:wait 2
 echo.
goto:EOF

:trayIcon
 tasklist|find /I "Tomcat7w.exe"
 If [%errorlevel%]==[0] (
	call:writetolog "Утилита Tomcat7w уже запущена."
	goto:EOF
 ) else (
	rem Как показала практика, при настроенной системе, со всеми "безопасными" фичами эта часть не работает
	rem более того, при попытке запустить тулзу, получаем ошибку 5 (Access denied)
	rem call:writetolog "Запускаем утилиту Tomcat7w."
	rem cd "%TOMCAT_HOME%"\bin\
	rem start Tomcat7w.exe //MS//Tomcat7
 )
goto:EOF

:writetolog
 set logdata=%~1
 @Echo %Date% %Time% %logdata%
 if [%STDOUT_REDIRECTED%]==[yes] @Echo %Date% %Time% %logdata% > CON
goto:EOF

:checkSirius
 cscript /NOLOGO C:\install\sirius_agent\checkSirius.vbs
goto:EOF

:wait
 ping -n %1 127.0.0.1 > NUL 2>&1
goto:EOF

:stopWaiting
 set /A stopwaiting = %1+1
goto:EOF

:renVers
if not exist %1%2 goto:EOF
if not [%3]==[] ( 
	set version=%3
) else ( 
	set version=0
)
If Exist %~1%~2.%version% (
 call:stopwaiting %version%
 call:renVers "%~1" "%~2" %stopwaiting%
) else (
 ren "%~1""%~2" %2.%version%
)
goto:EOF