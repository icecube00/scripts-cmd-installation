@echo off
@rem ����� ���⠫����
set SetupVersion=2.02.000

@rem ��।��塞 ⥪���� ����
for /f "tokens=1-4 delims=. " %%a in ('echo %DATE:/=.%') do (
 if [%%d]==[] (
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

@rem ��।��塞 ⥪�饥 �६�
set HOURS=%Time:~0,2%
set MINUTES=%Time:~3,2%

@rem ��� 䠩�� ��� �뢮�� ���� �ᯮ������ �ਯ�
set OUTPUT="%YEAR%_%MONTH%_%DAY%_%HOURS: =0%%MINUTES%_sirius_agent.log"

@rem �஢��塞 ࠧ�來���� ��.
if defined CommonProgramW6432 (set osversion=64) else (set osversion=32)

@rem �஢��塞 �᫨ ����祭� ��७��ࠢ����� �뢮�� � 䠩� ���� 㪠����� ���
if [%STDOUT_REDIRECTED%]==[] (
 set STDOUT_REDIRECTED=yes
 @rem ��頥� �࠭
 cls
 @rem �믮��塞 䠩� �ਯ�, �� � ��७��ࠢ������ �뢮��
 cmd.exe /c %0 %* >%OUTPUT% 2>&1
 @rem �����蠥� �믮������ �ਯ� � ����� ������ ERRORLEVEL
 exit /b %ERRORLEVEL%
)

@rem ���室�� � ��४��� C:\Install\sirius_agent\. ��� �ਡ�� �����ﬨ.
cd "C:\Install\sirius_agent\"

call:writetolog "****************************************************"
call:writetolog " ���⠫���� SIRIUS �����. ����� %SetupVersion%"

@rem �맮� ����� �����⮢�� ��६����� �।� ��� ����� ��⠭����
call:prepareEnv 0

@rem �஢��塞 ॣ������� ����ன�� � ���⠢�塞 ���祭�� ��� ���᪠ ���ଠ樨 � ᪮��஢����� 䠩���
call:checkLocale
if %errorlevel% equ 0 set copied="copied"
if %errorlevel% equ 1 set copied="᪮��஢���"
if %errorlevel% equ 100 set copied="�����४⭠� ������"

@rem �஢��塞 ����� IE. ����� ��� ����� ���� �� ���� 8.0
call:checkIE 8.0
@rem �᫨ �஢�ઠ ���ᨨ IE ��諠 �ᯥ譮, �஢��塞 ���⠢騪� ��
if %errorlevel% equ 0 call:checkVendor %1

@rem �᫨ ��६����� continue ࠢ�� false - �����蠥� ࠡ��� �ਯ� � ����� ������ 99
if [%continue%]==[false] (
 @rem �����頥� ��६���� �।� � ��室��� ���ﭨ�
 call:prepareEnv 1
 call:writetolog "****************************************************"
 exit /b 99
 goto:EOF
)

@rem �᫨ �ਯ� �� �맢�� ��� ��ࠬ��஢, �믮��塞 ���� main.
if [%1]==[] (
 call:main
) else (
 @rem ����, ��⠥��� ���� ���� � ��������� ��ࠬ���
 goto:%1
)
@rem �᫨ �� �뫮 ���, � � �� �� ������ �뫨 �������.
@rem �����頥� ��६���� �।� � ��室��� ���ﭨ�
call:prepareEnv 1
call:writetolog "ERROR: �訡�� ���⠫��樨 ����� SIRIUS."
goto:EOF

@rem �᭮���� ���� ���⠫����
:main
 call:writetolog "	��⠭�������� ⠩���� �� ���� NETBIOS."
 @rem �맮� ����� ����ன�� ��ࠬ��஢ NETBIOS.
 call:setParams
 @rem �맮� ����� ��⠭���� JRE.
 call:java
 @rem �᫨ JRE �ᯥ譮 ��⠭������, ��뢠�� ���� ��⠭���� �� Tomcat.
 if %errorlevel% equ 0 call:tomcat
 @rem �஢��塞 ����稥 ����� � ॥��� � ��� ��⠭���� ����� ������
 for /f "usebackq skip=4 tokens=2*" %%i in (`@reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Sirius agent" /v "InstallDate"`) do ( 
  @rem �᫨ ��� ᮢ������ � ⥪�饩, ���室�� � ����� Finish
  if [%%j]==[%YEAR%%MONTH%%DAY%] goto:Finish
 )

@rem ���� �஢�ન ������ ���஢������ �࠭� � ��� 㤠�����, �� ����室�����
:checkCached
for /f "tokens=2 delims== " %%a in ('type "C:\install\sirius_agent\sirius-atm.properties"^|find "cache.file"') do (
 set cachefile=%%~a
)
if exist "%cachefile:/=\%" (
 call:writetolog "		���⨬ ��� %cachefile:/=\%"
 del %cachefile:/=\% /q
)
goto:EOF

@rem �஢�ઠ ���ᨨ IE
:checkIE
 @rem ����祭�� ������� ��� � ��ࢮ�� �������� 䠩�� iexplore.exe ��稭�� � ����� %ProgramFiles% (������ ��������)
 for /f "tokens=*" %%a in ('cscript /NOLOGO C:\install\sirius_agent\siriusTools.js getPath "iexplore.exe" "%ProgramFiles%" true') do (set pathIE=%%a)
 @rem ����祭�� ���ᨨ 䠩�� iexplore.exe
 for /f "tokens=*" %%a in ('cscript /NOLOGO C:\install\sirius_agent\siriusTools.js checkFileVersion "%pathIE%" iexplore.exe %copied% fileV') do (set IEVersion=%%a)
 if %IEVersion% GEQ %1 (
  call:writetolog " ����� Internet Explorer (%IEVersion%)"
  call:writetolog " ��ࠢ�塞 �஡���� ���⠫��樨 IE8. regsvr32 actxprxy.dll"
  call regsvr32 /s actxprxy.dll
  exit /b 0
 ) else (
  call:writetolog "ERROR: ����� Internet Explorer (%IEVersion%) ���� �������쭮 �����⨬�� (%1)"
  if not defined continue set continue=false
  exit /b 1
 )
goto:EOF

@rem �஢�ઠ ���ᨨ JRE
:checkJava
 for /f "usebackq tokens=2*" %%i in (`@java -version 2^>^&1^|find "version"`) do (
  set version=%%~j
 )
 if not [%version%]==[] set version1=%version:.=%
 if not [%version1%]==[] (set JAVAVersion=%version1:_=%) else (set JAVAVersion="")

 if %JAVAVersion% GEQ %1 (
  set updateJava=false
  if ["%JAVA_HOME%"]==[""] (
   @rem ��⠭���� ��६����� �।� JAVA_HOME (��� ࠧ�, �� ��直� ��砩, ������ �� �ࠡ��뢠�� ���� ⠪)
   call:setEnvVar "JAVA_HOME" "%ProgramFiles%\Java\jre7"
   set "JAVA_HOME=%ProgramFiles%\Java\jre7"
  )
  if not [%1]==[0] call:writetolog "	��⠭�������� ����� JRE(%JAVAVersion%) �� �ॡ�� ����������."
  exit /b 0
 ) else (
  set updateJava=true
  if [%JAVAVersion%]==[""] (
   call:writetolog "	JRE �� ��⠭�����. ����室��� ��⠭����� JRE 7 update 80."
   exit /b 1
  )
  call:writetolog "	����室��� �������� ����� JRE(%JAVAVersion%) �� %1."
  @rem ���⨬ ��� ��⠭���� JRE �� ����稨
  if exist C:\install\sirius_agent\jre_install.log del C:\install\sirius_agent\jre_install.log /q /f
  exit /b 1
 )
goto:EOF

@rem �஢�ઠ ॣ�������� ����஥�
:checkLocale
 %wmicpath% os get oslanguage|find "1033" >NUL && exit /b 0
 %wmicpath% os get oslanguage|find "1049" >NUL && exit /b 1
exit /b 100

@rem �஢�ઠ �� Tomcat
:checkTomcat
 @rem ��⠭�������� �ࢨ� Tomcat
 net start|find /I "Tomcat7" && call net stop Tomcat7 > NUL 2>&1
 @rem ����砥� ����� �� Tomcat
 for /f "usebackq tokens=1* DELIMS=/" %%i in (`@JAVA -classpath "%tomcat_home%\lib\catalina.jar" org.apache.catalina.util.ServerInfo 2^>^&1^|find "Apache Tomcat"`) do (
  if not [%%j]==[] set TOMCATVersion=%%j
 )

 if [%TOMCATVersion%]==[] (
  call:writetolog " Tomcat �� ��⠭�����."
  set updateTomcat=true
  goto:EOF
 )
 call:writetolog " ��⠭����� Tomcat ���ᨨ %TOMCATVersion%." 

 if %TOMCATVersion% GEQ %1 (
  set updateTomcat=false
  call:writetolog " ���������� Tomcat �� �ॡ����"
 ) else (
  set updateTomcat=true
  call:writetolog " ����室��� �������� Tomcat �� ���ᨨ %1"
 )
goto:EOF

@rem �஢�ઠ ���⠢騪� ���
:checkVendor
 if [%~1]==[help] goto:EOF
 if [%~1]==[uninstall] goto:EOF
 call:writetolog " �஢�ઠ �����প� WEB-EXT."
 if not exist C:\SCS\ATM_h\ATM_WEB.exe (
  call:writetolog "ERROR: �� TellMe �� �����㦥��."
  if not defined continue set continue=TellMe
 ) else ( 
  call:checkWebExt
 )
goto:EOF

@rem �஢�ઠ ���ᨨ TellME, ᮣ��᭮ ���ᨨ WebExt
:checkWebExt
 @rem ����祭�� ������� ��� � ��ࢮ�� �������� 䠩�� atm_web.exe ��稭�� � ����� C:\SCS\ATM_h (������ ��������)
 for /f "tokens=*" %%a in ('cscript /NOLOGO C:\install\sirius_agent\siriusTools.js getPath "atm_web.exe" "C:\SCS\ATM_h" true') do (set pathFile=%%a)
 @rem ����祭�� ���ᨨ 䠩�� atm_web.exe
 for /f "tokens=*" %%a in ('cscript /NOLOGO C:\install\sirius_agent\siriusTools.js checkFileVersion "%pathFile%" atm_web.exe %copied% productV') do (
  set tellMeVersion=%%a
 )
 call:writetolog " ����� TellME (%tellMeVersion%)"
 @rem ��稭�� � ���ᨨ 029016002092 - web-ext ����祭 ��-㬮�砭�� � �� �ॡ�� ������ ���祩
 if %tellMeVersion:.=% GEQ 029016002092 (
  if not defined continue set continue=TellMe
  call:writetolog " �஢�ઠ WebEXT �� �㦭�."
 ) else (
  @rem �᫨ ����� ���� 029016002092 - �஢��塞 � ᥣ����譥� ERL, �� web-ext �� �⪫�祭.
  find /I ":WEB-EXT" C:\%YEAR%%MONTH%%DAY%.erl|find /I "disabled" > NUL 2>&1
  if not %errorlevel%==0 (
   if not defined continue set continue=TellMe
   call:writetolog " �����㦥�� �� TellMe � �����প�� WEB-EXT."
  ) else (
   if not defined continue set continue=TellMe
   call:writetolog "ERROR: �����㦥�� �� TellMe ��� �����প� WEB-EXT."
  )
 )
goto:EOF

@rem �஢�ઠ ������ ��⠭��������� wmic.exe
:checkWMIC
 for /f "tokens=*" %%a in ('cscript /NOLOGO C:\install\sirius_agent\siriusTools.js getPath "wmic.exe" "%SystemRoot%" false') do (set pathWMIC=%%a)
 if exist %pathWMIC%\wmic.exe (%pathWMIC%\wmic.exe os get oslanguage|find /i "wmic" && exit /b 999) else (exit /b 999)
exit /b 0

@rem ��ᯠ����� ��娢� � ����᪨�� ����ᠬ� ������ ������
:copy_resources
 for /f "tokens=2 delims== " %%a in ('type "C:\install\sirius_agent\sirius-atm.properties"^|find "path.images"') do (
  set pathresources=%%~a
 )
 call:writetolog "		����室��� �������� ������ � ����� %pathresources:/=\%"
 rmdir /s /q "%pathresources:/=\%"
 mkdir "%pathresources:/=\%"
 call:writetolog "		��稭��� �ᯠ����� �᭮���� ����ᮢ � %pathresources%" >unpack_main_resources.log 2>&1
 call rar x resources.rar -o+ -y -idp -inul "%pathresources:/=\%"\ >>unpack_main_resources.log 2>&1
 call:writetolog "		��ᯠ����� �����襭�." >>unpack_main_resources.log 2>&1
goto:EOF
 
@rem �����襭�� ����� ��⠭����
:finish
 @rem �஢��塞, � �� ����室����� ����᪠��, �ࢨ� Tomcat
 net start|find /I "Tomcat7" > NUL 2>&1
 if not [%errorlevel%]==[0] call net start TomCat7 > NUL 2>&1

 call:writetolog "	��⠭���� �����襭�."
 call:writetolog "****************************************************"
 @rem ������� ~ 3 ᥪ㭤�.
 call:wait 3
 @rem �����頥� ��६���� �।� � ��室��� ���ﭨ�
 call:prepareEnv 1
 exit
goto:EOF

@rem ����祭�� ࠧ��� RAM
:getRAMsize
 for /f "tokens=*" %%a in ('cscript /NOLOGO %wmicpath% os get TotalVisibleMemorySize') do (
  if not defined RAMSize set /A RAMSize=%%a/1024
 )
 call:writetolog "��ꥬ ����㯭�� ����⨢��� ����� = %RAMSize% ��"
 set /A minRAMSize=%RAMSize%/64
 set /A maxRAMSize=%RAMSize%/4
 set /A midRAMSize=%RAMSize%/2
goto:EOF

@rem ���ᠭ�� �����⨬�� ��ࠬ��஢ ����᪠ �ਯ�
:help
 call:writetolog "****************************************************"
 call:writetolog " ���⠪�� SETUP.CMD [��ࠬ���]"
 call:writetolog " ��ࠬ����: java, tomcat, sirius, uninstall"
 call:writetolog " 	java	 	 - ��⠭���� �ᥣ� ����� = ����� ��� ��ࠬ��஢"
 call:writetolog " 	tomcat	 	 - ��⠭���� �ᥣ�, �஬� java"
 call:writetolog " 	sirius	 	 - ��⠭���� ⮫쪮 SIRIUS-ATM.WAR"
 call:writetolog " 	uninstall	 - 㤠����� �த��."
 call:writetolog " 	uninstall silent - 㤠����� ��� ����ᮢ."
 call:writetolog " 	help	 	 - �� ᮮ�饭��."
 call:writetolog "****************************************************"
 call:writetolog "������ ���� ������, �� �� �த������."
 pause >NUL
goto:EOF

@rem ���� ��⠭���� JRE
:installJava
 call:setJavaName "Java Runtime 7 update 80"
 @rem ��⠭�������� �ࢨ� Tomcat
 net start|find /I "Tomcat7" && call net stop Tom�at7
 
 call:writetolog "	��⠭���� %JAVAName%"
 call setup_jre.exe /s /v "/qn IEXPLORER=1 REBOOT=Suppress JAVAUPDATE=0 WEBSTARTICON=0 /L C:\install\sirius_agent\jre_install.log" > NUL 2>&1
 @rem �஢��塞 �� JRE �뫠 ��⠭������ �ᯥ譮.
 find /I "completed successfully" C:\install\sirius_agent\jre_install.log > NUL
 if [%errorlevel%]==[0] (
  @rem ��⠭�������� ��ଥ���� �।� JAVA_HOME
  call:setEnvVar "JAVA_HOME" "%ProgramFiles%\Java\jre7"
  @rem �⪫�砥� ��⮧���� JavaQuickStarterService
  net start|find /I "Java Quick Starter" && call net stop "Java Quick Starter" > NUL 2>&1
  sc config JavaQuickStarterService start= disabled
  call:writetolog "	%JAVAName% �ᯥ譮 ��⠭�����"
  exit /b 0
 ) else (
  call:writetolog "	���� ��⠭���� %JAVAName%"
  @rem �����祬 GUID ��⠭�������� JRE
  if not defined currentGUID set currentGUID=2F0%osversion%17080FF
  @rem ��뢠�� ���� �⪠� ��⠭���� JRE
  call:rollBack java
  call:writetolog "****************************************************"
  @rem �����頥� ��६���� �।� � ��室��� ���ﭨ�
  call:prepareEnv 1
  goto:EOF
 )

@rem ���� ��⠭���� �� Tomcat
:installTomcat
 call:writetolog "	��⠭���� Apache TomCat 7.0.xx"
 @rem �᫨ ⥪��� ����� Tomcat �����⭠, ����� ���� ᭠砫� 㤠���� �ࢨ�
 if not [%TOMCATVersion%]==[] call "%TOMCAT_HOME%\uninstall.exe" -ServiceName="Tomcat7" /S >NUL 2>&1
 @rem ����᪠�� ���砫���� (/S) ��⠭���� �� Tomcat
 call setup_tomcat.exe /S

 @rem ����祭�� ������� ��� � ��ࢮ�� �������� 䠩�� Tomcat7.exe ��稭�� � ����� %ProgramFiles% (������ ��������)
 for /f "tokens=*" %%a in ('cscript /NOLOGO C:\install\sirius_agent\siriusTools.js getPath "Tomcat7.EXE" "%ProgramFiles%" false') do (set pathTomCat=%%a)
 
 @rem ��⠭���� ��६����� �।� TOMCAT_HOME (��� ࠧ�, �� ��直� ��砩, ������ �� �ࠡ��뢠�� ���� ⠪)
 if not defined TOMCAT_HOME call:setEnvVar "TOMCAT_HOME" "%pathTomCat%"
 if not defined TOMCAT_HOME set TOMCAT_HOME=%pathTomCat%
 
 @rem �맮� ����� ����ன�� �� Tomcat
 call:setupTomcat
 @rem �᫨ ��⠭���� � ����ன�� ��諨 �ᯥ譮
 if %errorlevel% equ 0 (
  call:writetolog "	Apache TomCat 7.0.xx �ᯥ譮 ��⠭�����"
  @rem �맮� ����� ��⠭���� ������᪮�� �ਫ������
  call:sirius
 )
goto:EOF

:java
 call:writetolog "----------------------------------------------------"
 call:writetolog "	�஢��塞 ����稥 ��⠭�������� JRE."
 @rem �맮� ����� �஢�ન ���ᨨ JRE
 call:checkJava 17080
 @rem �᫨ ����� JRE �� ᮮ⢥����� ��������, ��⠭�������� ����室���� �����
 if %errorlevel% equ 1 goto:installJava
 exit /b 0
goto:EOF

@rem ���� ����஢���� �ᯮ������ �������, ����� ��⠥��� �뢮���� echo � ���᮫�
:logCommand
 set second="%~2...."
 if [%second:~1,4%]==[find] (
  for /f "tokens=1*" %%a in ('%~1 2^>^&1^|%~2') do (
   call:writetolog "		%%a %%b"
  )
 ) else (
  for /f "tokens=1*" %%a in ('%~1 2^>^&1') do (
   call:writetolog "		%%a %%b"
  )
 )
goto:EOF

@rem ���� �����⮢�� ��६����� �।�
:prepareEnv
 if [%1]==[0] (
    @rem ����砥� CScript ��-㬮�砭��, ����������� � ���ᯮ������
    call cscript //H:CScript >NUL 2>&1
	@rem �맮� ����� ��⠭���� ॣ�������� ����஥�
    call:setRegional
 )
 @rem �맮� ����� �஢�ન WMIC
 call:checkWMIC
 if [%errorlevel%]==[999] (
  set wmicpath=C:\install\sirius_agent\wmic.js
 ) else (
  set wmicpath=wmic
 )
 @rem �����頥� HScript ��-㬮�砭��, ����������� � ���ᯮ������
 if [%1]==[1] call cscript //H:WScript >NUL 2>&1
goto:EOF

@rem ���� ���������� "�ᮡ� �।���" ��६����� �।�
:refreshVars
if defined CommonProgramW6432 (set osversion=64) else (set osversion=32)
if not defined currentGUID set currentGUID=2F0%osversion%17080FF
set "JAVA_HOME=%ProgramFiles%\Java\jre7"
goto:EOF

@rem ���� �⪠� ��⠭����
:rollBack
 if [%1]==[tomcat] (
  @rem ��⠭�������� �ࢨ� Tomcat
  net start|find /I "Tomcat7" && call net stop Tom�at7
  
  @rem �������� ��६����� �।� SIRIUS_ATM_PROPERTIES
  call:setEnvVar "SIRIUS_ATM_PROPERTIES" "remove" remove
  call:writetolog "----------------------------------------------------"
  @rem �஢��塞 ����稥 ����饭���� �३-����� �� Tomcat � �� ����室����� ��⠭��������
  tasklist|find "tomcat7w.exe" && taskkill /F /IM tomcat7w.exe
  call:writetolog "	�⬥�� ��⠭���� Apache TomCat 7.0.xx"
  @rem �������� �ࢨ� Tomcat
  call "%TOMCAT_HOME%\uninstall.exe" -ServiceName="Tomcat7" /S
  @rem ����祭�� ��� � Tomcat7w.lnk ��稭�� � ����� %ALLUSERSPROFILE% (������ ��������)
  for /f "tokens=*" %%a in ('cscript /NOLOGO C:\install\sirius_agent\siriusTools.js getPath "Tomcat7w.lnk" "%ALLUSERSPROFILE%" true') do (
   @rem �᫨ Tomcat7w.lnk �������, � 㤠�塞
   if exist "%%a\Startup\Tomcat7w.lnk" del "%%a\StartUp\Tomcat7w.lnk" /Q /F > NUL 2>&1
  )
  @rem �������� ��४�ਨ TOMCAT_HOME
  rd "%TOMCAT_HOME%" /s /q > NUL 2>&1
  @rem �������� ��६����� �।� TOMCAT_HOME
  call:setEnvVar "TOMCAT_HOME" "remove" remove
  @rem �������� ����ᥩ ॥��� ��ନ஢����� (��⨢��) ���⠫���஬ Tomcat
  @rem ��⮧���� �३-�����
  reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "ApacheTomcatMonitor7.0_Tomcat7" /f >NUL 2>&1
  @rem �����⠫���� �� Tomcat
  reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Apache Tomcat 7.0 Tomcat7" /f >NUL 2>&1
  @rem ��ࢨ� �� Tomcat
  reg delete "HKLM\SYSTEM\CurrentControlSet\Services\Tomcat7" /f >NUL 2>&1
  @rem ����ன�� �� Tomcat
  reg delete "HKCU\Software\Apache Software Foundation" /f >NUL 2>&1
  @rem ������ � �� Tomcat � ᯨ᪥ �ணࠬ�
  reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\MenuOrder\Start Menu\Programs\Apache Tomcat 7.0 Tomcat7" /f >NUL 2>&1
  @rem ����ன�� �� Tomcat
  reg delete "HKLM\SOFTWARE\Apache Software Foundation" /f >NUL 2>&1
  @rem ����ன�� �ࢨ� �� Tomcat
  reg delete "HKLM\SYSTEM\ControlSet001\Enum\Root\LEGACY_TOMCAT7" /f >NUL 2>&1
  @rem ����ன�� �ࢨ� �� Tomcat
  reg delete "HKLM\SYSTEM\ControlSet003\Enum\Root\LEGACY_TOMCAT7" /f >NUL 2>&1
  @rem ����ன�� �ࢨ� �� Tomcat
  reg delete "HKLM\SYSTEM\CurrentControlSet\Enum\Root\LEGACY_TOMCAT7" /f >NUL 2>&1
  call:writetolog "	��⠭���� Apache TomCat 7.0.xx �⬥����"
  @rem �맮� ����� �⪠� JRE
  call:rollBack java
 )
 if [%1]==[java] (
  @rem �맮� ����� �ନ஢���� GUID 㤠�塞�� ���ᨨ JRE
  call:getJAVAGUID
  @rem �맮� ����� �ନ஢���� ������ ���ᨨ JRE
  call:setJavaName
  call:writetolog "----------------------------------------------------"
  call:writetolog "	�⬥�� ��⠭���� %JAVAName%"
  @rem �������� ����� ॥��� ��⮧���᪠ ����஥� ����� ������ ��᫥ ��ࢮ� ��१���㧪�
  reg delete "HKLM\Software\Microsoft\Windows\CurrentVersion\RunOnce" /v "SirusAgent" /f >NUL 2>&1
  @rem ����, ��⠭���� � �⪫�祭�� ��⮧���᪠ �ࢨ� Java Quick Starter
  net start|find /I "Java Quick Starter" > NUL 2>&1
  if [%errorlevel%]==[0] (
   call net stop "Java Quick Starter" > NUL 2>&1
   sc config JavaQuickStarterService start= disabled
  )
  @rem �맮� ����� �����⠫��樨 JRE
  call:UninstallJAVA
  @rem �������� ��६����� �।� JAVA_HOME
  call:setEnvVar "JAVA_HOME" "remove" remove
  call:writetolog "	��⠭���� %JAVAName% �⬥����"
 )
goto:EOF

@rem ���� ��⠭���� ��६����� �।�
:setEnvVar
 call:writetolog "	���⥬��� ��६����� %~1"
 call:writetolog "	���祭�� ��६����� %~2"
 call:logCommand "cscript /NOLOGO C:\install\sirius_agent\siriusTools.js setEnvVar %~1 %~2 %~3"
goto:EOF

@rem ���� ��।������ ������ ���ᨨ JRE
:setJavaName
 if not ["%~1"]==[""] (
  set JAVAName=%~1
 ) else (
  @rem �맮� ����� ��।������ GUID ���ᨨ JRE
  call:getJAVAGUID
  for /f "tokens=3* skip=2" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{26A24AE4-039D-4CA4-87B4-%currentGUID%}" /v DisplayName') do (
   set JAVAName=%%a %%b
  )
 )
goto:EOF

@rem ���� �ਭ㤨⥫쭮� ��⠭���� ॣ�������� ����஥� - �����
:setRegional
 rundll32.exe shell32,Control_RunDLL intl.cpl,,/f:"C:\install\sirius_agent\regionalSettings.ini"
goto:EOF

@rem ���� ����ன�� �� Tomcat
:setupTomcat
 @rem ���室 � ��४��� %TOMCAT_HOME%\bin\
 pushd "%TOMCAT_HOME%\bin\"
 @rem �맮� ����� ��।������ ࠧ��� ����⨢��� �����
 call:getRAMsize
 @rem �맮� ����� ���������� ���祭�� ����᪨ ������ ��६�����
 call:refreshVars

 call:writetolog "	�஢��塞 � ��⠭�������� Tomcat"
 net start|find /I "Tomcat7" && call net stop Tomcat7
 call:writetolog "	�஢��塞 � ��⠭�������� JRE"
 tasklist|find /I "java.exe" && taskkill /F /IM java.exe

 if exist Tomcat7.exe (
  call:writetolog "	����ࠨ���� �ᯮ��㥬�� ����� JRE"
  "Tomcat7.exe" //US//Tomcat7 --Jvm "%JAVA_HOME%\bin\client\jvm.dll"
  @rem � 䠩�� server.xml �࠭���� ᯥ���᪨� (⮭���) ����ன�� �� Tomcat
  call:writetolog "	������� 䠩� ����஥� server.xml"
  xcopy /C /R /Y "C:\Install\sirius_agent\server.xml" "%TOMCAT_HOME%\conf\"|find /I %copied% 2>&1 && call:Tomcat7_1 "	����ன�� ����஢�� UTF-8."
  
  @rem Service startup type <manual|auto>
  "Tomcat7.exe" //US//Tomcat7 --Startup auto 2>&1|find /I "[warn]" 2>&1 && goto:Tomcat7_0 "	��� ����᪠ �ࢨ� = AUTO" && goto:EOF
  call:Tomcat7_1 "	��� ����᪠ �ࢨ� = AUTO"
 
  @rem Initial memory pool size in MB 
  "Tomcat7.exe" //US//Tomcat7 --JvmMs %minRAMSize% 2>&1|find /I "[warn]" 2>&1 && goto:Tomcat7_0 "	���⮢� ࠧ��� �㫠 ����� � MB = %minRAMSize%" && goto:EOF
  call:Tomcat7_1 "	���⮢� ࠧ��� �㫠 ����� � MB = %minRAMSize%"

  @rem Maximum memory pool size in MB
  "Tomcat7.exe" //US//Tomcat7 --JvmMx %maxRAMSize% 2>&1|find /I "[warn]" 2>&1 && goto:Tomcat7_0 "	���ᨬ���� ࠧ��� �㫠 ����� � MB = %maxRAMSize%" && goto:EOF
  call:Tomcat7_1 "	���ᨬ���� ࠧ��� �㫠 ����� � MB = %maxRAMSize%"

  @rem Maximum Thread pool size in KB
  "Tomcat7.exe" //US//Tomcat7 --JvmSs %maxRAMSize% 2>&1|find /I "[warn]" 2>&1 && goto:Tomcat7_0 "	���ᨬ���� ࠧ��� �㫠 ��⮪�� � �B = %maxRAMSize%" && goto:EOF
  call:Tomcat7_1 "	���ᨬ���� ࠧ��� �㫠 ��⮪�� � KB = %maxRAMSize%"

  @rem ��⠭���� ����஥� JVM ��� �� Tomcat.
  "Tomcat7.exe" //US//Tomcat7 --JvmOptions "-server#-Dcatalina.base=%TOMCAT_HOME%#-Dcatalina.home=%TOMCAT_HOME%#-Djava.endorsed.dirs=%TOMCAT_HOME%\endorsed#-Djava.io.tmpdir=%TOMCAT_HOME%\temp#-Djava.net.preferIPv4Stack=true#-Djava.util.logging.config.file=%TOMCAT_HOME%\conf\logging.properties#-Djava.util.logging.manager=org.apache.juli.ClassLoaderLogManager#-Djavax.net.ssl.trustStore=%TOMCAT_HOME%\bin\sirius#-XX:+AggressiveOpts#-XX:+UseParallelGC#-XX:ParallelGCThreads=2" 2>&1|find /I "[warn]" 2>&1 && goto:Tomcat7_0 "	����ன�� ����७���� �࠭���� ��� TomCat" && goto:EOF
  call:Tomcat7_1 "	����ன�� ����७���� �࠭���� ��� TomCat"
	
  @rem Enable using of native Apache Tomcat APR. It should enable a high scalbility and performance.
  xcopy /C /R /Y "C:\Install\sirius_agent\tcnative-1.dll" "%TOMCAT_HOME%"|find /I %copied% 2>&1 && call:Tomcat7_1 "	������祭�� ��⨢��� ������⥪� APR."
  exit /b 0
 ) else (
  goto:Tomcat7_0 "	�������⭠� �訡��."
 )
 popd

goto:EOF

@rem ���� ��⠭���� � ����ன�� ������ ������
:sirius
 call:writetolog "	�஢��塞 � ��⠭�������� Tomcat"
 net start|find /I "Tomcat7" && call net stop TomCat7
 call:writetolog "	�஢��塞 � ��⠭�������� JRE"
 tasklist|find /I "java.exe" && taskkill /F /IM java.exe
 call:writetolog "----------------------------------------------------"
 call:writetolog "	��⠭���� sirius-atm.war"
 @rem �������� ��४�ਨ � �ᯠ������묨 ࠡ�稬� ����ﬨ 䠩���
 if exist "%TOMCAT_HOME%\work" rd "%TOMCAT_HOME%\work" /s /q >NUL 2>&1
 @rem �������� ��४�ਨ � �ᯠ�������� ���ᨥ� ������ ������
 if exist "%TOMCAT_HOME%\webapps\sirius-atm" rd "%TOMCAT_HOME%\webapps\sirius-atm" /s /q >NUL 2>&1
 @rem �஢�ઠ ����⢮����� WAR 䠩�� ������ ������
 if exist "C:\install\sirius_agent\sirius-atm.war" (
  @rem ����஢���� WAR 䠩�� ������ ������ � ��४��� web-�ਫ������ �� Tomcat
  xcopy /C /R /Y "C:\install\sirius_agent\sirius-atm.war" "%TOMCAT_HOME%\webapps\"|find /I %copied% && call:writetolog "	sirius-atm.war - ᪮��஢�� � ����� WEBAPPS"
  @rem �� ����稨 �������⥫��� ���㫥� - ����஢���� �� � ��४��� lib �� Tomcat
  if exist "C:\install\sirius_agent\WEB-INF\lib" (
   call:writetolog "		����஢���� ���㫥� � lib"
   xcopy /S /C /R /Y "C:\install\sirius_agent\WEB-INF\lib\*.*" "%TOMCAT_HOME%\lib\"|find /I %copied%
   @rem ��⠭���� ��६����� �।� CLASSPATH
   call:setEnvVar "CLASSPATH" "%TOMCAT_HOME%\lib"
   @rem �������� ��४�ਨ � �������⥫�묨 ����ﬨ
   rd "C:\install\sirius_agent\WEB-INF" /s /q >NUL 2>&1
  )
  @rem �஢�ઠ ����⢮����� 䠩�� ����஥� ������ ������
  if exist "C:\install\sirius_agent\sirius-atm.properties" (
   @rem ����஢���� 䠩�� ����஥� ������ ������ � ��४��� web-�ਫ������ �� Tomcat
   xcopy /C /R /Y "C:\install\sirius_agent\sirius-atm.properties" "%TOMCAT_HOME%\webapps\"|find /I %copied% && call:writetolog "	sirius-atm.properties - ᪮��஢�� � ����� WEBAPPS"
   @rem ��⠭���� ��६����� �।� SIRIUS_ATM_PROPERTIES
   call:setEnvVar "SIRIUS_ATM_PROPERTIES" "%TOMCAT_HOME%\webapps"
   @rem �맮� ����� �஢�ન ������ ���஢������ �࠭�
   call:checkCached
   @rem �஢�ઠ ����⢮����� ��娢� � ����᪨�� ����ᠬ� ������ ������
   if exist "C:\install\sirius_agent\resources.rar" (
    call:writetolog "	������ ��娢 � ����ᠬ�"
	@rem �맮� ����� �ᯠ����� ��娢� � ����ᠬ�
    call:copy_resources
   )
   
   @rem �஢�ઠ ����⢮����� 䠩�� � ���譨� ���⮬
   if exist "C:\install\sirius_agent\fonts\PTRoubleSans.ttf" (
    call:writetolog "	��⠭���� ���� PTRoubleSans.ttf"
	@rem ��⠭���� � ॣ������ ���� � �� Windows
    call:logCommand "cscript /NOLOGO C:\install\sirius_agent\siriusTools.js installFont ^"PTRoubleSans.ttf^" ^"C:\install\sirius_agent\fonts^""
   ) else (
    call:writetolog "	WARN: ���� PTRoubleSans.ttf �� ������."
   )
  )
  
  @rem �����㥬 䠩� ����७���� �࠭���� � ��४��� %TOMCAT_HOME%\bin\
  if exist "%TOMCAT_HOME%\bin\sirius" call:writetolog "	������塞 䠩� ����७���� �࠭����"
  xcopy /C /R /Y C:\install\sirius_agent\sirius "%TOMCAT_HOME%\bin\"|find /I %copied% > NUL 2>&1 && call:Tomcat7_1 "	����஢���� 䠩�� ����७���� �࠭����"
  
  @rem �맮� ����� ����஥� ������ �ਢ易���� � ����ன��� ����
  call:userSettings
  
  @rem �ਬ������ ����஥� ॥��� ᯥ����� ��� ⥪�饣� ���⠢騪� ��� (�ਡ�� �����ﬨ TellMe)
  if exist "C:\install\sirius_agent\%continue%.reg" regedit /s C:\install\sirius_agent\%continue%.reg
  
  @rem �ਬ������ ����஥� ॥��� ᯥ����� ��� ������ ������
  if exist "C:\install\sirius_agent\sirius_agent.reg" regedit /s C:\install\sirius_agent\sirius_agent.reg
  call:writetolog "	�ਬ��塞 ����ன�� ��� ࠡ��� � �業��ﬨ ����������樨"
  
  @rem �맮� ����� ����ன�� XML ��ୠ�� ��� ��������������
  call:setFrontDataXML
  @rem ������ ���� ��⠭���� ������ ������ � ॥���
  reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Sirius agent" /v "InstallDate" /t REG_SZ /d "%YEAR%%MONTH%%DAY%" /f >NUL 2>&1
  call:writetolog "	SIRIUS-ATM.WAR �ᯥ譮 ��⠭�����"
 ) else (
  call:writetolog "	sirius-atm.war �� ������."
  call:writetolog "	��� 㤠����� ��⠭�������� �த�⮢: "
  call:writetolog "		1. JRE7"
  call:writetolog "		2. Apache Tomcat7"
  call:writetolog "	�믮����� setup.cmd uninstall"
  call:writetolog "****************************************************"
  @rem ������� ~ 3 ᥪ㭤�
  call:wait 3
  @rem �����頥� ��६���� �।� � ��室��� ���ﭨ�
  call:prepareEnv 1
 )
goto:EOF

@rem ����� �����⠫��樨 ������ ������
:sUninstall
 call:writetolog "	�믮������ �����⠫���� �த�� SIRIUS."
 @rem �맮� ����� �⪠� ��⠭���� Tomcat
 call:rollBack tomcat
 @rem �������� ���� ��⠭���� JRE �� ����稨
 if exist C:\Install\sirius_agent\jre_install.log del C:\Install\sirius_agent\jre_install.log /s /q > NUL 2>&1
 @rem �������� ����� ॥��� �� ����� ��⠭���� � 㤠����� �ணࠬ�
 reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Sirius agent" /f > NUL 2>&1

 call:writetolog "	�����⠫���� �த�� �����襭�."
 call:writetolog "****************************************************"
 @rem �����頥� ��६���� �।� � ��室��� ���ﭨ�
 call:prepareEnv 1 
 @rem ������� ~ 3 ᥪ㭤�
 call:wait 3
 if [%~2]==[silent] goto:EOF 
 
 @rem �����뢠�� ���� � �।�०������ � ����室����� �१���㧪�
 for /f "tokens=*" %%a in ('cscript /NOLOGO C:\install\sirius_agent\isContinue.vbs "����室��� �ந����� ��१���㧪� ��������!"') do (
  if [%%a]==[_go_] (
   @rem �ਭ㤨⥫쭠� ��१���㧪� ��
   call:writetolog "	���짮��⥫� ��ࠫ �ਭ㤨⥫��� ��१��㧪� ��������."
   shutdown -r -t 00 -f
   goto:EOF
  )
 )
goto:EOF

@rem ���� ��⠭���� �� Tomcat
:tomcat
 call:writetolog "----------------------------------------------------"
 @rem ��⠭���� ��६����� TEMP_TOMCAT_HOME
 for /f "tokens=*" %%a in ('cscript /NOLOGO C:\install\sirius_agent\siriusTools.js setEnvVar "TOMCAT_HOME"') do (set TEMP_TOMCAT_HOME=%%a)
 
 @rem �맮� ����� �஢�ન ���ᨨ Tomcat
 call:checkTomcat 7.0.41
 @rem ��⠭���� ��� ����ன�� Tomcat
 if [%updateTomcat%]==[true] goto:installTomcat
 if [%updateTomcat%]==[false] call:setupTomcat
 @rem �᫨ ��⠭���� ��� ����ன�� Tomcat ��諨 �ᯥ譮 - �맮� ����� ��⠭���� � ����ன�� ������ ������
 if %errorlevel% equ 0 call:sirius
 exit /b 0
goto:EOF

@rem ���� �⪠� ��⠭���� Tomcat � ������� � ���
:tomcat7_0
 call:writetolog "	%~1"
 call:writetolog "	���� ��⠭���� Apache TomCat 7"
 @rem �맮� ����� �⪠� ��⠭���� Tomcat
 call:rollBack tomcat
 call:writetolog "	�ந������ �⪠� ��������� � ��⥬�"
 call:writetolog "****************************************************"
 @rem ������� ~ 3 ᥪ㭤�
 call:wait 3
 @rem �����頥� ��६���� �।� � ��室��� ���ﭨ�
 call:prepareEnv 1
 exit
goto:EOF

@rem ���� ����஢���� ��⠭���� ����஥� �� Tomcat
:tomcat7_1
 call:writetolog "	%~1"
 exit /b 0
goto:EOF

@rem ���� �����⠫��஢���� ������ ������
:uninstall
 @rem �맮� ����� �஢�ન JRE
 call:checkJava 0
 @rem �᫨ ���� ��ࠬ��� silent - �맢��� ���� �宩 �����⠫��樨
 if [%~2]==[silent] goto:sUninstall
 @rem �����뢠�� ���� � �।�०������ � ����⪥ 㤠����� �த��
 for /f "tokens=*" %%a in ('cscript /NOLOGO C:\install\sirius_agent\isContinue.vbs "�� ᮡ�ࠥ��� ��������� 㤠���� �ନ����� ����� SIRIUS!"') do (
  if [%%a]==[stop] (
   @rem ���뢠�� �����⠫����, �᫨ ���짮��⥫� �⪠�����
   call:writetolog "	�����⠫���� �த�� �� �믮�����. �⪠� ���짮��⥫�."
   exit
  )
 )
@rem ����᫮��� ��室 � ���� �宩 �����⠫��樨
goto:sUninstall

@rem ���� ��⠭���� ����஥� ���짮��⥫� �易���� � ����
:userSettings
 call:writetolog "	�����⮢�� ����஥� ���짮��⥫�."
 @rem �஢��塞 �� ����஥� �� �맮� ᯥ����� ����஥� ࠭��
 type c:\scs\atm_h\startup\vendor_start.bat|find "userSettings.bat" >NUL 2>&1
 if not [%errorlevel%]==[0] (
  call:writetolog "		����室��� ����� �ࠢ�� � ����ன�� ���짮��⥫�."
  echo. >>c:\scs\atm_h\startup\vendor_start.bat
  echo call c:\scs\atm_h\startup\userSettings.bat >> c:\scs\atm_h\startup\vendor_start.bat
  call:writetolog "		������� 䠩� vendor_start.bat"
  echo. >c:\scs\atm_h\startup\userSettings.bat
  echo if exist "C:\install\sirius_agent\%continue%.reg" regedit /s C:\install\sirius_agent\%continue%.reg >>c:\scs\atm_h\startup\userSettings.bat
  call:writetolog "		������ 䠩� userSettings.bat"
 )
goto:EOF

@rem ���� �������� (ping �� 127.0.0.1 �믮������ ���-� ᥪ㭤�)
:wait
 ping -n %1 127.0.0.1 > NUL 2>&1
goto:EOF

@rem ���� ����� � ���
:writetolog
 set logdata=%~1
 @echo %Date% %Time% %logdata%
 if [%STDOUT_REDIRECTED%]==[yes] @echo %Date% %Time% %logdata% > CON
goto:EOF

@rem ���� ����஥� NetBIOS
:netBIOSinfo
 call:logCommand "wmic nicconfig get caption, index, TcpipNetbiosOptions"
goto:EOF

:switchOn
@rem ����祭�� NETBIOS
 if defined command call:setParams
 call:logCommand "wmic nicconfig where (TcpipNetbiosOptions=2) call SetTcpipNetbios 1"
goto:EOF

:switchOff
@rem �⪫�祭�� NETBIOS
 call:logCommand "wmic nicconfig where (TcpipNetbiosOptions=1 OR TcpipNetbiosOptions=0) call SetTcpipNetbios 2"
goto:EOF

:setParams
rem ����ன�� NETBIOS
 @reg add "HKLM\SYSTEM\CurrentControlSet\Services\NetBT\Parameters" /v "NameSrvQueryCount" /t REG_DWORD /d 0x0 /f >NUL &&  call:writetolog "NameSrvQueryCount = 0"
 @reg add "HKLM\SYSTEM\CurrentControlSet\Services\NetBT\Parameters" /v "NameSrvQueryTimeout" /t REG_DWORD /d 0x1 /f >NUL && call:writetolog "NameSrvQueryTimeout = 1"
 @reg add "HKLM\SYSTEM\CurrentControlSet\Services\NetBT\Parameters" /v "BcastNameQueryCount" /t REG_DWORD /d 0x0 /f >NUL && call:writetolog "BcastNameQueryCount = 0" 
 @reg add "HKLM\SYSTEM\CurrentControlSet\Services\NetBT\Parameters" /v "BcastQueryTimeout" /t REG_DWORD /d 0x1 /f >NUL && call:writetolog "BcastQueryTimeout = 1"
goto:EOF


@rem ���� 㤠����� JRE
:UninstallJAVA
for /f "usebackq skip=4 tokens=2*" %%i in (`@reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{26A24AE4-039D-4CA4-87B4-2F03217080FF}" /v "UninstallString"`) do ( 
 call %%j /qn /norestart
)
for /f "usebackq skip=4 tokens=2*" %%i in (`@reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{26A24AE4-039D-4CA4-87B4-2F83217080FF}" /v "UninstallString"`) do ( 
 call %%j /qn /norestart
)
goto:EOF

@rem ���� ��।������ GUID ���ᨨ JRE
:getJAVAGUID
 @reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{26A24AE4-039D-4CA4-87B4-2F8%osversion%%JAVAVersion%FF}" > NUL 2>&1
 if [%errorlevel%]==[0] (
  set currentGUID=2F8%osversion%%JAVAVersion%FF
 ) else (
  set currentGUID=2F0%osversion%%JAVAVersion%FF)
 )
goto:EOF

@rem ���� ����ன�� XML ��ୠ�� ��� ��������������
:setFrontDataXML
 set /a FrontDataXMLcount = 1
 reg query "HKCR\WOSA/XFS_ROOT\ATM\PaymentSystems\NDC\Protocol"|find "FrontDataXML"
 @rem �᫨ ������ ࠧ��� ॥���, �஢��� ᪮�쪮 � ��� 㦥 ���� ����ᥩ
 if %errorlevel% equ 0 call :checkCount
 @rem ������塞 ����� ������, �᫨ �㦭�
 if %FrontDataXMLcount% gtr 0 call :addParameter
goto:EOF

@rem ���� ��⠭���� ��ࠬ�஢ XML ��ୠ�� ��� �������������� � ॥���
:addParameter
 call:writetolog "		��ࠬ���� �� �������. �ਬ��塞 ����ன��."
 echo reg add "HKCR\WOSA/XFS_ROOT\ATM\PaymentSystems\NDC\Protocol\FrontDataXML\%FrontDataXMLcount%" /v "ParamName" /t REG_SZ /d "SUIT" /f
 echo reg add "HKCR\WOSA/XFS_ROOT\ATM\PaymentSystems\NDC\Protocol\FrontDataXML\%FrontDataXMLcount%" /v "ParamVarName" /t REG_SZ /d "SUIT_NUMBER" /f
goto:EOF

@rem ���� �஢�ન ������⢠ ��ࠬ�஢ XML ��ୠ�� ��� �������������� � ॥���
:checkCount
 call:writetolog "		������ ࠧ��� ॥��� FrontDataXML"
 for /f "tokens=8 delims=\" %%a in ('reg query "HKCR\WOSA/XFS_ROOT\ATM\PaymentSystems\NDC\Protocol\FrontDataXML" /f "*" /k^|find "FrontDataXML"') do (
  echo %%a
  if %FrontDataXMLcount% gtr 0 call:addNew %%a
 )
goto:EOF

@rem ���� ���������� ��ࠬ�� XML ��ୠ�� ��� �������������� � ॥���
:addNew
 reg query "HKCR\WOSA/XFS_ROOT\ATM\PaymentSystems\NDC\Protocol\FrontDataXML\%~1" /f "SUIT"
 if %errorlevel% equ 0 (
  call:writetolog "		��ࠬ���� 㦥 ����஥��. ����୮� �ਬ������ �ய�饭�."
  set /a FrontDataXMLcount=-1
 ) else (
  set /a FrontDataXMLcount=%FrontDataXMLcount%+1
 )
goto:EOF
