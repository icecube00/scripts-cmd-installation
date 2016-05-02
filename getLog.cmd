@echo off
Set GLVersion=0.38

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

Set OUTPUT="%YEAR%_%MONTH%_%DAY%_%Time:~0,2%%Time:~3,2%_getLog.log"
if [%STDOUT_REDIRECTED%]==[] (
	set STDOUT_REDIRECTED=yes
	cls
	cmd.exe /c %0 %* >%OUTPUT% 2>&1
	exit /b %ERRORLEVEL%
)
set curdir=C:\Install\sirius_agent
cd %curdir%
call:prepareEnv 0

if [%1]==[dump] set isdump=dump

pushd %curdir%
if not exist %curdir%\getLog ( md %curdir%\getLog )
popd

call:needNDC %*

call:writetolog "****************************************************"
call:writetolog "       Сборщик логов АС СИРИУС. Версия %GLVersion%"
call:writetolog "----------------------------------------------------"
call:writetolog " Сбор логов клиентского приложения..."
call:SIRIUS 30
call:TOMCAT 30
call:writetolog "----------------------------------------------------"
call:writetolog " Сбор логов TellMe (ЕГПО)..."
call:SCS_ACTIVEX
if [%needNDC%]==[true] (
	call:SCS_NDC 30
	call:SCS_ERL 30
) else (
	call:SCS_ERL 5
)

if [%needINSTALL%]==[true] (
	call:INSTALL
)

If [%needPING%]==[true] (
	call:checkServerSirius 150 tomcat ""
	call:checkServerSirius 150 direct ""
)

call:writetolog "----------------------------------------------------"
call:WINDOWS
call:REGISTRY
call:writetolog " 	Настройки видеоадаптера"
call:getVideoSettings
call:writetolog "	 	Текущее разрешение экрана: %resolution%."
call:writetolog "		Максимальное разрешение экрана: %maxResolution%."
call:writetolog "****************************************************"

copy %curdir%\*.log %curdir%\getLog\
call:prepareEnv 1
if exist %curdir%\getLog.arc del %curdir%\getLog.arc /q
call:pack2rar
exit /b 0
goto:EOF

::******************************************************
::***********          Функции           ***************
::******************************************************
::--------------------- Общие --------------------------
:writetolog
 set logdata=%~1
 @Echo %Date% %Time% %logdata%
 if [%STDOUT_REDIRECTED%]==[yes] @Echo %Date% %Time% %logdata% > CON
goto:EOF

:wait
 ping -n %1 127.0.0.1 > NUL 2>&1
goto:EOF


::--------------------- getLog -------------------------
:pack2rar
if exist %curdir%\getLog.rar ( del %curdir%\getLog.rar /q )
if not exist %curdir%\getLog.arc (
	echo %curdir%\getLog\* >%curdir%\getLog.arc
	echo .\%OUTPUT:"=% >>%curdir%\getLog.arc
	echo. >>%curdir%\getLog.arc
)

if exist %curdir%\rar.exe (
	cd %curdir%
	call rar a getLog -ac -ep1 -r0 -y -s -idp -m5 @getLog.arc
	rd %curdir%\getLog  /s /q >NUL 2>&1
) else (
	call:pack2ZIP
)
goto:EOF

:SIRIUS
call:writetolog " 	Сбор логов АС СИРИУС. [за %1 дней]"
xcopy /C /R /Y "%curdir%\*_sirius_agent.log" %curdir%\getLog\Install\
cd %TOMCAT_HOME%\
cd ..
call:getDir "%CD%\sirius-logs\"
call:getDir "%TOMCAT_HOME%\"
for /f "tokens=2 delims== " %%a in ('type %SIRIUS_ATM_PROPERTIES%\sirius-atm.properties^|find "path.images"') do (
	set pathresources=%%~a
)

call:getDir "%pathresources%\"
call:dirWithMD5 "%TOMCAT_HOME%\webapps" recoursive
call:switchDate %1 "%CD%\sirius-logs" "*.*"

If Exist sirius-logs (
	call:writetolog "		SUCCESS: Найдена папка sirius-logs."
	xcopy /C /R /Y /D:%mnth%-%dy%-%yr% "%CD%\sirius-logs\*" %curdir%\getLog\Sirius\
	xcopy /C /R /Y "%TOMCAT_HOME%\webapps\*.properties" %curdir%\getLog\Sirius\
	If [%needPING%]==[] If Exist %curdir%\checkSirius.js call:checkServerSirius 1 tomcat
	If [%isdump%]==[dump] (
		call:DUMP "%CD%\sirius-logs" ".bak"
		SETLOCAL
		set needtodump=""
		call:DUMP "%CD%\sirius-logs" ".log"
		ENDLOCAL
	)
) else (
	call:writetolog "		ERROR: Папка sirius-logs не найдена."
)
call:getVersion atm_h.exe "C:\SCS\ATM_h" "TellMe"
call:getVersion atm_web.exe "C:\SCS\ATM_h" WEB-EXT
goto:EOF

:INSTALL
 call:writetolog "	Собираем логи установки клиента СИРИУС."
 call:getDir "/s %curdir%\"
 xcopy /C /R /Y "%curdir%\*.log" %curdir%\getLog\Install\
goto:EOF

:TOMCAT
call:writetolog " 	Сбор логов Tomcat. [за %1 дней]"
cd %TOMCAT_HOME%\
call:switchDate %1 "%TOMCAT_HOME%\logs" "*.*"
If Exist "logs" (
	call:writetolog "		SUCCESS: Найдена папка logs."
	xcopy /C /R /Y /D:%mnth%-%dy%-%yr% "logs\*" %curdir%\getLog\Tomcat\
	if [%isdump%]==[dump] call:DUMP "%TOMCAT_HOME%\logs" ".log"
) else (
	call:writetolog "		ERROR: Папка logs не найдена."
)
@echo off
goto:EOF

:SCS_ACTIVEX
call:writetolog " 	Список зарегистрированных ActiveX компонент."
%wmicpath% path Win32_ClassicCOMClassSetting where "TypeLibraryId='{80AA54A9-7E00-44A5-B8F3-9C5E312E74E3}'" get Caption,Progid,VersionIndependentProgId >> %curdir%\getLog\SCS_ACTIVEX.txt
%wmicpath% path Win32_ClassicCOMClassSetting where "TypeLibraryId='{A8D7E7C0-2DE7-4DA6-B933-A8A616CB03D8}'" get Caption,Progid,VersionIndependentProgId >> %curdir%\getLog\SCS_ACTIVEX.txt
goto:EOF

:SCS_NDC
call:writetolog " 	Сбор логов NDC. [за %1 дней]"
call:getDir C:\SCS\
call:switchDate %1 "C:\SCS\atm_h\DataNDC" "*.*"
If Exist C:\SCS\atm_h\DataNDC\ (
	call:writetolog "		SUCCESS: Найдена папка DataNDC."
	xcopy /C /R /Y /D:%mnth%-%dy%-%yr% C:\SCS\atm_h\DataNDC\* %curdir%\getLog\SCS_NDC\
	call:writetolog "	Конфигурационные файлы."
	xcopy /S /C /R /Y "C:\SCS\*.ini" %curdir%\getLog\SCS_NDC\INI\
	xcopy /S /C /R /Y "C:\SCS\*.cfg" %curdir%\getLog\SCS_NDC\CFG\
	call:writetolog "	Настройки сценария УС."
	xcopy /S /C /R /Y "C:\SCS\*.fi_" %curdir%\getLog\SCS_NDC\FIT\
	xcopy /S /C /R /Y "C:\SCS\*.sc_" %curdir%\getLog\SCS_NDC\SCREEN\
	xcopy /S /C /R /Y "C:\SCS\*.st_" %curdir%\getLog\SCS_NDC\STATE\
	call:writetolog "	NDC журналы УС."
	call:switchDate %1 "C:\SCS" "*.prj"
	xcopy /S /C /R /Y /D:%mnth%-%dy%-%yr% "C:\SCS\*.prj" %curdir%\getLog\SCS_NDC\JOURNALS\PRJ\
	call:switchDate %1 "C:\SCS" "*.prr"
	xcopy /S /C /R /Y /D:%mnth%-%dy%-%yr% "C:\SCS\*.prr" %curdir%\getLog\SCS_NDC\JOURNALS\PRR\
	call:switchDate %1 "C:\SCS" "*.prf"
	xcopy /S /C /R /Y /D:%mnth%-%dy%-%yr% "C:\SCS\*.prf" %curdir%\getLog\SCS_NDC\JOURNALS\PRF\
	if [%isdump%]==[dump] (
		call:DUMP "C:\SCS\atm_h\DataNDC" ".ndc"
		SETLOCAL
		set needtodump=""
		call:DUMP "C:\SCS\atm_h\DataNDC" ".stf"
		ENDLOCAL
	)
) else (
	call:writetolog "		ERROR: Папка DataNDC не найдена."
)
goto:EOF

:SCS_ERL
call:writetolog " 	Сбор логов ERL. [за %1 дней]"
call:getDir C:\*.ERL
call:getDir C:\*.HWR
call:switchDate %1 "C:\" "*.ERL"

If Exist C:\%YEAR%%MONTH%%DAY%*.ERL (
	call:writetolog "		SUCCESS: Найдены файлы *.ERL,*.HWR,*.ERR."
	xcopy /C /R /Y /D:%mnth%-%dy%-%yr% C:\*.ERL  %curdir%\getLog\SCS_ERL\
	call:switchDate %1 "C:\" "*.HWR"
	xcopy /C /R /Y /D:%mnth%-%dy%-%yr% C:\*.HWR  %curdir%\getLog\SCS_ERL\
	call:switchDate %1 "C:\SCS" "*.ERR"
	xcopy /C /R /Y /D:%mnth%-%dy%-%yr% C:\SCS\*.ERR  %curdir%\getLog\SCS_ERL\ERR\
) else (
	call:writetolog "		ERROR: Файл %YEAR%%MONTH%%DAY%.ERL не найден. TellMe не работает."
	xcopy /C /R /Y /D:%mnth%-%dy%-%yr% C:\*.ERL  %curdir%\getLog\SCS_ERL\
	call:switchDate %1 "C:\" "*.HWR"
	xcopy /C /R /Y /D:%mnth%-%dy%-%yr% C:\*.HWR  %curdir%\getLog\SCS_ERL\
	call:switchDate %1 "C:\SCS\" "*.ERR"
	xcopy /C /R /Y /D:%mnth%-%dy%-%yr% C:\SCS\*.ERR  %curdir%\getLog\SCS_ERL\ERR\
)

if [%isdump%]==[dump] (
	call:DUMP "C:" ".erl"
	SETLOCAL
	set needtodump=""
	call:DUMP "C:" ".hwr"
	ENDLOCAL
	call:DUMP "C:\SCS" ".err"
)
goto:EOF

:WINDOWS
call:writetolog " Сбор логов ОС Windows..."
set path2eventquery=C:\Install\sirius_agent
If Exist %SYSTEMROOT% (
 call:writetolog "		Информация о системе."
 rem TODO Зарегить CMDLIB.WSC
 cscript /NOLOGO %path2eventquery%\eventquery.vbs /r 1 /fo csv /v /l system^|find "CMDLIB.WSC"
 If [%errorlevel%]==[0] ( 
  IF NOT EXIST %SYSTEMROOT%\system32\CMDLIB.WSC xcopy %path2eventquery%\CMDLIB.WSC %SYSTEMROOT%\system32\CMDLIB.WSC /C /R /Y
  cd %SYSTEMROOT%\system32
  call regsvr32 /i /s "%SYSTEMROOT%\system32\CMDLIB.WSC"
  cd %curdir%
 )
 md %curdir%\getLog\systeminfo
 call:writetolog "			Сбор системных событий."
 CALL cscript /NOLOGO %path2eventquery%\eventquery.vbs /r 2000 /fo csv /v /l system > %curdir%\getLog\systeminfo\system.csv
 call:writetolog "			Сбор событий приложений."
 CALL cscript /NOLOGO %path2eventquery%\eventquery.vbs /r 2000 /fo csv /v /l application > %curdir%\getLog\systeminfo\application.csv
 call:writetolog "			Сбор событий безопасности."
 CALL cscript /NOLOGO %path2eventquery%\eventquery.vbs /r 2000 /fo csv /v /l security > %curdir%\getLog\systeminfo\security.csv
 IF EXIST %SYSTEMROOT%\system32\systeminfo.exe 	CALL %SYSTEMROOT%\system32\systeminfo.exe /FO LIST > %curdir%\getLog\systeminfo\info_computer.txt
 rem IF EXIST %SYSTEMROOT%\system32\qprocess.exe   	CALL %SYSTEMROOT%\system32\qprocess.exe * > %curdir%\getLog\systeminfo\process.txt
 call:listProcesses
 call:writetolog "		Список установленных программ."	
 call:getInstalled
) else (
 call:writetolog "		ERROR: Отсутсвует ОС Windows!? Серьёзно?"
)
goto:EOF

:REGISTRY
call:writetolog " Сбор настроек реестра ОС Windows..."
If Exist "%SystemRoot%\regedit.exe" (
 call:writetolog "		Системный реестр."
 md %curdir%\getLog\Registry
 %SystemRoot%\regedit /e /a %curdir%\getLog\Registry\IE.TXT "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Internet Explorer"
 %SystemRoot%\regedit /e /a %curdir%\getLog\Registry\WOSA.TXT "HKEY_CLASSES_ROOT\WOSA/XFS_ROOT"
 %SystemRoot%\regedit /e /a %curdir%\getLog\Registry\SCS.TXT  "HKEY_LOCAL_MACHINE\SOFTWARE\SCS"
 %SystemRoot%\regedit /e /a %curdir%\getLog\Registry\IE_settings.TXT "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Internet Settings" 
 %SystemRoot%\regedit /e /a %curdir%\getLog\Registry\NetBT_settings.TXT "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\NetBT\Parameters"
) else (
 call:writetolog "		ERROR: Невозможно получить информацию."
)
goto:EOF

:DUMP
call:writetolog "		Архивация логов %~1\*%~2."
if [%~2]==[] ( 
 echo "%~1\*" > %curdir%\getLog.arc
) else (
 echo "%~1\*%~2" > %curdir%\getLog.arc
)
echo .\%OUTPUT:"=% >>%curdir%\getLog.arc
echo. >>%curdir%\getLog.arc

call:pack2rar
del "%~1\*%~2" /q
copy /Y "%curdir%\getLog.rar" "%~1\%YEAR%_%MONTH%_%DAY%_%Time:~0,2%%Time:~3,2%_dump%~2.rar"
goto:EOF

:pack2ZIP
if exist %curdir%\getLog.zip ( del %curdir%\getLog.zip /q )
find " " "%curdir%\getLog.arc"|zip.exe -r "%curdir%\getLog.zip" -@
goto:EOF

:checkServerSirius
call:writetolog "-------------------------------------------------------"
call:writetolog "Проверка доступности сервера СИРИУС."
call:checkLocale
If %errorlevel% equ 0 for /f "usebackq tokens=2,3" %%a in (`netsh interface ip show address^|find "IP Address"`) do set localIP=%%b
If %errorlevel% equ 1 for /f "usebackq tokens=1,2" %%a in (`netsh interface ip show address^|find "IP"`) do set localIP=%%b
If not defined localIP set localIP=""

if %~1 EQU 1 (
 call:logCommand "cscript /NOLOGO %curdir%\checkSirius.js %~1 %~2 %localIP%"
) else (
 cscript /NOLOGO %curdir%\checkSirius.js %~1 %~2 %localIP% >>%curdir%\getLog\ping.csv
)

goto:EOF

:needNDC
if defined isdump set needNDC=true
echo "%*"|find /I "NDC"
if [%errorlevel%]==[0] set needNDC=true
echo "%*"|find /I "INSTALL"
if [%errorlevel%]==[0] set needINSTALL=true
echo "%*"|find /I "PING"
if [%errorlevel%]==[0] set needPING=true
goto:EOF

:getDir
call:writetolog "-------------------------------------------------------"
call:writetolog "	Сборка листинга файлов в директории %~1"
dir /s "%~1" >> %curdir%\getLog\dir.txt
goto:EOF

:getVersion
rem %1 - имя файла
rem %2 - путь к файлу
rem %3 - название приложения
for /f "tokens=*" %%a in ('cscript /NOLOGO %curdir%\getPath.vbs "%1" "%~2" false') do (Set pathFile="%%a")
call:writetolog "		Версия %~3"
for /f "tokens=*" %%a in ('cscript /NOLOGO %curdir%\checkFV.js "%pathFile%" %1 %copied% full') do (
 call:writetolog "		 %%a."
 Set fileVersion=%%a
)
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
 %wmicpath% os get oslanguage|find "1033" >NUL && set copied=copied && exit /b 0
 %wmicpath% os get oslanguage|find "1049" >NUL && set copied=скопировано && exit /b 1
exit /b 100

:getInstalled
set UNISTALL=HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall
for /f "tokens=7 delims=\" %%a IN ('reg query "%UNISTALL%"') do (
 for /f "tokens=1,2,*" %%b in ('reg query "%UNISTALL%\%%a"^|find /I "DisplayName"') do (
  call:writetolog 		"%%d"
 )
)
goto:EOF

:getVideoSettings
 for /f "tokens=*" %%a in ('cscript /NOLOGO %curdir%\screenResolution.js') do (
  set resolution=%%a
 )
 for /f "tokens=*" %%a in ('cscript /NOLOGO %curdir%\video_info.js') do (
  set maxResolution=%%a
 )
goto:EOF

:switchDate
call:getLatestFileDate "%~2" "%~3"
for /f "tokens=* delims=0" %%a in ("%MONTH%") do set "tmpMNT=%%a"
for /f "tokens=* delims=0" %%a in ("%DAY%") do set "tmpDAY=%%a"
set /A tempValue = 28-%1+%tmpDAY%

if %tmpDAY% LEQ %1 (
 if %tempValue% LEQ 0 (
  set /A dy=1
 ) else (
  set /A dy=28-%1+%tmpDAY%
 )
 set /A mnth=%tmpMNT%-1
 set /A yr=%YEAR%
 if %tmpMNT% equ 1 (
  set /A yr=%YEAR%-1
  set mnth=12
 )
) else (
 set /A dy=%tmpDAY%-%1
 set /A yr=%YEAR%
 set /A mnth=%tmpMNT%
)
goto:EOF

:listProcesses
 rem wmic /output:%curdir%\getLog\systeminfo\processWMI.txt process get description, executablepath
 tasklist /V >%curdir%\getLog\systeminfo\process.txt
goto:EOF

:prepareEnv
if [%1]==[0] call cscript //H:CScript //Nologo >NUL 2>&1
call:checkWMIC
if [%errorlevel%]==[999] (
 set wmicpath=%curdir%\wmic.js
) else (
 set wmicpath=wmic
)
if [%1]==[1] call cscript //H:WScript >NUL 2>&1
goto:EOF

:checkWMIC
 for /f "tokens=*" %%a in ('cscript /NOLOGO %curdir%\getPath.vbs "wmic.exe" "%SystemRoot%" false') do (Set pathWMIC=%%a)
 if exist %pathWMIC%\wmic.exe (%pathWMIC%\wmic.exe os get oslanguage|find /i "wmic" && exit /b 999) else (exit /b 999)
exit /b 0

:getLatestFileDate
pushd %1
for /f "tokens=* delims=" %%a in ('dir /a:-d /b /o:-d "%~2"') do (
 set LatestDate=%%~ta
 goto:getLatestFileFINISH
)

:getLatestFileFINISH
for /f "tokens=1 delims= " %%a in ('echo %LatestDate:/=.%') do (
 set LatestDate=%%a
 call:writetolog "Latest date: %LatestDate%"
)

for /f "tokens=1-4 delims=." %%a in ('echo %LatestDate:/=.%') do (
 If [%RegSettings%]==[True] (
  set YEAR=%%c
  set MONTH=%%b
  set DAY=%%a
 ) else (
  set YEAR=%%c
  set MONTH=%%a
  set DAY=%%b
 )
)
popd
goto:EOF

:dirWithMD5
call:writetolog "Listing directory: %~1" >> %curdir%\getLog\dirMD5.txt
if [%2]==[] (
 for /f "tokens=* delims= " %%a in ('dir /a:-d /b "%~1"') do (
  cscript /NOLOGO %curdir%\getHash.js "%~1\%%a" >> %curdir%\getLog\dirMD5.txt
 )
) else (
 for /f "tokens=* delims= " %%a in ('dir /a:-d /b /s "%~1"') do (
  cscript /NOLOGO %curdir%\getHash.js "%%a" >> %curdir%\getLog\dirMD5.txt
 )
)
goto:EOF