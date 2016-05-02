@echo off
Set NBVersion=0.03

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

Set OUTPUT="%YEAR%_%MONTH%_%DAY%_%Time:~0,2%%Time:~3,2%_setNETBIOS.log"
if [%STDOUT_REDIRECTED%]==[] (
	set STDOUT_REDIRECTED=yes
	cls
	cmd.exe /c %0 %* >%OUTPUT% 2>&1
	exit /b %ERRORLEVEL%
)


call:writetolog "****************************************************"
call:writetolog "       Настройка NETBIOS. Версия %NBVersion%"
call:writetolog "----------------------------------------------------"
call:checkWMIC
if [%errorlevel%]==[999] (
	call:writetolog "	       ERROR: Отсутвует WMIC.EXE!"
	exit /b 999
)

call:getParams %*
if defined command (
	call:%command%
) else (
	call:switchOn
	call:wait 3
	call:switchOff
)
goto:EOF

:wait
 ping -n %1 127.0.0.1 > NUL 2>&1
goto:EOF

:writetolog
 set logdata=%*
 set tempdata=%logdata:>= %
 set newlogdata=%tempdata:"=%
 @Echo %Date% %Time% %newlogdata%
 if [%STDOUT_REDIRECTED%]==[yes] @Echo %Date% %Time% %newlogdata% > CON
goto:EOF

:netBIOSinfo
call:logCommand "wmic nicconfig get caption, index, TcpipNetbiosOptions"
goto:EOF

:switchOn
REM Включение NETBIOS
if defined command call:setParams
call:logCommand "wmic nicconfig where (TcpipNetbiosOptions=2) call SetTcpipNetbios 1"
goto:EOF

:switchOff
REM Отключение NETBIOS
call:logCommand "wmic nicconfig where (TcpipNetbiosOptions=1 OR TcpipNetbiosOptions=0) call SetTcpipNetbios 2"
goto:EOF

:setParams
REM Настройка NETBIOS
call:writetolog "NameSrvQueryCount = 0"
@reg add "HKLM\SYSTEM\CurrentControlSet\Services\NetBT\Parameters" /v "NameSrvQueryCount" /t REG_DWORD /d 0x0 /f|find " "
call:writetolog "NameSrvQueryTimeout = 1"
@reg add "HKLM\SYSTEM\CurrentControlSet\Services\NetBT\Parameters" /v "NameSrvQueryTimeout" /t REG_DWORD /d 0x1 /f|find " "
call:writetolog "BcastNameQueryCount = 0"
@reg add "HKLM\SYSTEM\CurrentControlSet\Services\NetBT\Parameters" /v "BcastNameQueryCount" /t REG_DWORD /d 0x0 /f|find " "
call:writetolog "BcastQueryTimeout = 1"
@reg add "HKLM\SYSTEM\CurrentControlSet\Services\NetBT\Parameters" /v "BcastQueryTimeout" /t REG_DWORD /d 0x1 /f|find " "
goto:EOF

:showHelp
call:writetolog "	Утилита setNetBios для управления и конфигурирования сервиса NETBIOS"
call:writetolog "	Синтаксис:"
call:writetolog "		setNetBios [parameter]"
call:writetolog "		Доступные параметры:"
call:writetolog "			on 	- включить сервис NETBIOS"
call:writetolog "			off 	- отключить сервис NETBIOS"
call:writetolog "			set	- настроить NETBIOS"
call:writetolog "			info 	- информация о состоянии сервиса"
call:writetolog "			help 	- это сообщение"
call:writetolog "	Нажмите любую клавишу для выхода."
@pause>nul
goto:EOF

:logCommand
 set logCommand=%1
 set second="%~2...."
 If [%second:~1,4%]==[find] (
	for /f "tokens=1*" %%a in (`%logCommand% 2^>^&1^|%~2`) do (
		call:writetolog "		%%a %%b"
	)
 ) else (
	for /f "tokens=1*" %%a in ('%logCommand% 2^>^&1') do (
		call:writetolog "		%%a %%b"
	)
 )
goto:EOF

:getParams
REM Чтение параметров переданных скрипту
 if not defined command echo "%*"|find /I "ON" && set command=switchOn
 if not defined command echo "%*"|find /I "OFF" && set command=switchOff
 if not defined command echo "%*"|find /I "SET" && set command=setParams
 if not defined command echo "%*"|find /I "INFO" && set command=netBIOSinfo
 if not defined command echo "%*"|find /I "HELP" && set command=showHelp
goto:EOF

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