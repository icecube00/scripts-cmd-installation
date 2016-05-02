@echo off
Set HPVersion=0.05

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

Set OUTPUT="%YEAR%_%MONTH%_%DAY%_%Time:~0,2%%Time:~3,2%_httpPinger.log"
if [%STDOUT_REDIRECTED%]==[] (
	set STDOUT_REDIRECTED=yes
	cls
	cmd.exe /c %0 %* >%OUTPUT% 2>&1
	exit /b %ERRORLEVEL%
)
set curdir=C:\Install\sirius_agent
cd %curdir%
call:prepareEnv 0
call:writetolog "*******************************************************"
call:writetolog "      Анализатор связи АС СИРИУС. Версия %HPVersion%"

call:writetolog "-------------------------------------------------------"
call:checkLocale
If %errorlevel% equ 0 for /f "usebackq tokens=2,3" %%a in (`netsh interface ip show address^|find "IP Address"`) do set localIP=%%b
If %errorlevel% equ 1 for /f "usebackq tokens=1,2" %%a in (`netsh interface ip show address^|find "IP"`) do set localIP=%%b
If not defined localIP set localIP=""

call:checkServerSirius 1500 tomcat %localIP%
call:checkServerSirius 1500 direct %localIP%
call:prepareEnv 1

call %curdir%\getLog.cmd
exit /b 0
goto:EOF

::--------------------- Общие --------------------------
:writetolog
 set logdata=%~1
 @Echo %Date% %Time% %logdata%
 if [%STDOUT_REDIRECTED%]==[yes] @Echo %Date% %Time% %logdata% > CON
goto:EOF

:wait
 ping -n %1 127.0.0.1 > NUL 2>&1
goto:EOF

:checkServerSirius
call:writetolog "  Проверка доступности сервера СИРИУС."
cscript /NOLOGO C:\install\sirius_agent\checkSirius.js %~1 %~2 %~3
goto:EOF

:logCommand
 set second="%~2...."
 If [%second:~1,4%]==[find] (
	for /f "tokens=1*" %%a in ('%~1 2^>^&1^|%~2') do (
		call:writetolog "		%%a %%b"
	)
 ) else (
	for /f "tokens=1*" %%a in ('%~1 2^>^&1') do (
		call:writetolog "		%%a %%b"
	)
 )
goto:EOF

:checkLocale
 %pathWMIC% os get oslanguage|find "1033" >NUL && exit /b 0
 %pathWMIC% os get oslanguage|find "1049" >NUL && exit /b 1
exit /b 100

:prepareEnv
if [%1]==[0] call cscript //H:CScript >NUL 2>&1
call:checkWMIC
if [%errorlevel%]==[999] (
	set wmicpath=C:\install\sirius_agent\wmic.js
) else (
	set wmicpath=wmic
)
if [%1]==[1] call cscript //H:WScript >NUL 2>&1
goto:EOF

:checkWMIC
	for /f "tokens=*" %%a in ('cscript /NOLOGO C:\install\sirius_agent\getPath.vbs "wmic.exe" "%SystemRoot%" false') do (Set pathWMIC=%%a)
	if exist %pathWMIC%\wmic.exe (%pathWMIC%\wmic.exe os get oslanguage|find /i "wmic" && exit /b 999) else (exit /b 999)
exit /b 0