@echo off
@rem Версия инсталлятора
set SetupVersion=2.02.000

@rem Определяем текущую дату
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

@rem Определяем текущее время
set HOURS=%Time:~0,2%
set MINUTES=%Time:~3,2%

@rem Имя файла для вывода лога исполнения скрипта
set OUTPUT="%YEAR%_%MONTH%_%DAY%_%HOURS: =0%%MINUTES%_sirius_agent.log"

@rem Проверяем разрядность ОС.
if defined CommonProgramW6432 (set osversion=64) else (set osversion=32)

@rem Проверяем если включено перенаправление вывода в файл лога указанный выше
if [%STDOUT_REDIRECTED%]==[] (
 set STDOUT_REDIRECTED=yes
 @rem Очищаем экран
 cls
 @rem Выполняем файл скрипта, но с перенаправлением вывода
 cmd.exe /c %0 %* >%OUTPUT% 2>&1
 @rem Завершаем выполнение скрипта с кодом возврата ERRORLEVEL
 exit /b %ERRORLEVEL%
)

@rem Переходим в директорию C:\Install\sirius_agent\. Она прибита гвоздями.
cd "C:\Install\sirius_agent\"

call:writetolog "****************************************************"
call:writetolog " Инсталлятор SIRIUS агента. Версия %SetupVersion%"

@rem Вызов блока подготовки переменных среды для процесса установки
call:prepareEnv 0

@rem Проверяем региональные настройки и выставляем значение для поиска информации о скопированных файлах
call:checkLocale
if %errorlevel% equ 0 set copied="copied"
if %errorlevel% equ 1 set copied="скопировано"
if %errorlevel% equ 100 set copied="некорректная локаль"

@rem Проверяем версию IE. Сейчас она дожна быть не ниже 8.0
call:checkIE 8.0
@rem Если проверка версии IE прошла успешно, проверяем поставщика ПО
if %errorlevel% equ 0 call:checkVendor %1

@rem Если переменная continue равна false - завершаем работу скрипта с кодом возврата 99
if [%continue%]==[false] (
 @rem Возвращаем переменные среды в исходное состояние
 call:prepareEnv 1
 call:writetolog "****************************************************"
 exit /b 99
 goto:EOF
)

@rem Если скрипт был вызван без параметров, выполняем блок main.
if [%1]==[] (
 call:main
) else (
 @rem Иначе, пытаемся найти блок с названием параметра
 goto:%1
)
@rem Если все было хорошо, то сюда мы не должны были попасть.
@rem Возвращаем переменные среды в исходное состояние
call:prepareEnv 1
call:writetolog "ERROR: Ошибка инсталляции агента SIRIUS."
goto:EOF

@rem Основной блок инсталлятора
:main
 call:writetolog "	Устанавливаем таймаут на опрос NETBIOS."
 @rem Вызов блока настройки параметров NETBIOS.
 call:setParams
 @rem Вызов блока установки JRE.
 call:java
 @rem Если JRE успешно установлена, вызываем блок установки СП Tomcat.
 if %errorlevel% equ 0 call:tomcat
 @rem Проверяем наличие записи в реестре о дате установки агента СИРИУС
 for /f "usebackq skip=4 tokens=2*" %%i in (`@reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Sirius agent" /v "InstallDate"`) do ( 
  @rem Если дата совпадает с текущей, переходим к блоку Finish
  if [%%j]==[%YEAR%%MONTH%%DAY%] goto:Finish
 )

@rem Блок проверки наличия кэшированного экрана и его удаление, при необходимости
:checkCached
for /f "tokens=2 delims== " %%a in ('type "C:\install\sirius_agent\sirius-atm.properties"^|find "cache.file"') do (
 set cachefile=%%~a
)
if exist "%cachefile:/=\%" (
 call:writetolog "		Чистим кэш %cachefile:/=\%"
 del %cachefile:/=\% /q
)
goto:EOF

@rem Проверка версии IE
:checkIE
 @rem Получение полного пути к первому экземпляру файла iexplore.exe начиная с папки %ProgramFiles% (включая вложенные)
 for /f "tokens=*" %%a in ('cscript /NOLOGO C:\install\sirius_agent\siriusTools.js getPath "iexplore.exe" "%ProgramFiles%" true') do (set pathIE=%%a)
 @rem Получение версии файла iexplore.exe
 for /f "tokens=*" %%a in ('cscript /NOLOGO C:\install\sirius_agent\siriusTools.js checkFileVersion "%pathIE%" iexplore.exe %copied% fileV') do (set IEVersion=%%a)
 if %IEVersion% GEQ %1 (
  call:writetolog " Версия Internet Explorer (%IEVersion%)"
  call:writetolog " Исправляем проблемы инсталляции IE8. regsvr32 actxprxy.dll"
  call regsvr32 /s actxprxy.dll
  exit /b 0
 ) else (
  call:writetolog "ERROR: Версия Internet Explorer (%IEVersion%) ниже минимально допустимой (%1)"
  if not defined continue set continue=false
  exit /b 1
 )
goto:EOF

@rem Проверка версии JRE
:checkJava
 for /f "usebackq tokens=2*" %%i in (`@java -version 2^>^&1^|find "version"`) do (
  set version=%%~j
 )
 if not [%version%]==[] set version1=%version:.=%
 if not [%version1%]==[] (set JAVAVersion=%version1:_=%) else (set JAVAVersion="")

 if %JAVAVersion% GEQ %1 (
  set updateJava=false
  if ["%JAVA_HOME%"]==[""] (
   @rem Установка переменной среды JAVA_HOME (два раза, на всякий случай, иногда не срабатывает даже так)
   call:setEnvVar "JAVA_HOME" "%ProgramFiles%\Java\jre7"
   set "JAVA_HOME=%ProgramFiles%\Java\jre7"
  )
  if not [%1]==[0] call:writetolog "	Установленная версия JRE(%JAVAVersion%) не требует обновления."
  exit /b 0
 ) else (
  set updateJava=true
  if [%JAVAVersion%]==[""] (
   call:writetolog "	JRE не установлен. Необходимо установить JRE 7 update 80."
   exit /b 1
  )
  call:writetolog "	Необходимо обновить версию JRE(%JAVAVersion%) до %1."
  @rem Чистим лог установки JRE при наличии
  if exist C:\install\sirius_agent\jre_install.log del C:\install\sirius_agent\jre_install.log /q /f
  exit /b 1
 )
goto:EOF

@rem Проверка региональных настроек
:checkLocale
 %wmicpath% os get oslanguage|find "1033" >NUL && exit /b 0
 %wmicpath% os get oslanguage|find "1049" >NUL && exit /b 1
exit /b 100

@rem Проверка СП Tomcat
:checkTomcat
 @rem Останавливаем сервис Tomcat
 net start|find /I "Tomcat7" && call net stop Tomcat7 > NUL 2>&1
 @rem Получаем версию СП Tomcat
 for /f "usebackq tokens=1* DELIMS=/" %%i in (`@JAVA -classpath "%tomcat_home%\lib\catalina.jar" org.apache.catalina.util.ServerInfo 2^>^&1^|find "Apache Tomcat"`) do (
  if not [%%j]==[] set TOMCATVersion=%%j
 )

 if [%TOMCATVersion%]==[] (
  call:writetolog " Tomcat не установлен."
  set updateTomcat=true
  goto:EOF
 )
 call:writetolog " Установлен Tomcat версии %TOMCATVersion%." 

 if %TOMCATVersion% GEQ %1 (
  set updateTomcat=false
  call:writetolog " Обновление Tomcat не требуется"
 ) else (
  set updateTomcat=true
  call:writetolog " Необходимо обновить Tomcat до версии %1"
 )
goto:EOF

@rem Проверка поставщика ППО
:checkVendor
 if [%~1]==[help] goto:EOF
 if [%~1]==[uninstall] goto:EOF
 call:writetolog " Проверка поддержки WEB-EXT."
 if not exist C:\SCS\ATM_h\ATM_WEB.exe (
  call:writetolog "ERROR: ПО TellMe не обнаружено."
  if not defined continue set continue=TellMe
 ) else ( 
  call:checkWebExt
 )
goto:EOF

@rem Проверка версии TellME, согласно версии WebExt
:checkWebExt
 @rem Получение полного пути к первому экземпляру файла atm_web.exe начиная с папки C:\SCS\ATM_h (включая вложенные)
 for /f "tokens=*" %%a in ('cscript /NOLOGO C:\install\sirius_agent\siriusTools.js getPath "atm_web.exe" "C:\SCS\ATM_h" true') do (set pathFile=%%a)
 @rem Получение версии файла atm_web.exe
 for /f "tokens=*" %%a in ('cscript /NOLOGO C:\install\sirius_agent\siriusTools.js checkFileVersion "%pathFile%" atm_web.exe %copied% productV') do (
  set tellMeVersion=%%a
 )
 call:writetolog " Версия TellME (%tellMeVersion%)"
 @rem Начиная с версии 029016002092 - web-ext включен по-умолчанию и не требует наличия ключей
 if %tellMeVersion:.=% GEQ 029016002092 (
  if not defined continue set continue=TellMe
  call:writetolog " Проверка WebEXT не нужна."
 ) else (
  @rem Если версия ниже 029016002092 - проверяем в сегодняшнем ERL, что web-ext не отключен.
  find /I ":WEB-EXT" C:\%YEAR%%MONTH%%DAY%.erl|find /I "disabled" > NUL 2>&1
  if not %errorlevel%==0 (
   if not defined continue set continue=TellMe
   call:writetolog " Обнаружено ПО TellMe с поддержкой WEB-EXT."
  ) else (
   if not defined continue set continue=TellMe
   call:writetolog "ERROR: Обнаружено ПО TellMe без поддержки WEB-EXT."
  )
 )
goto:EOF

@rem Проверка наличия установленного wmic.exe
:checkWMIC
 for /f "tokens=*" %%a in ('cscript /NOLOGO C:\install\sirius_agent\siriusTools.js getPath "wmic.exe" "%SystemRoot%" false') do (set pathWMIC=%%a)
 if exist %pathWMIC%\wmic.exe (%pathWMIC%\wmic.exe os get oslanguage|find /i "wmic" && exit /b 999) else (exit /b 999)
exit /b 0

@rem Распаковка архива с графическими ресурсами клиента СИРИУС
:copy_resources
 for /f "tokens=2 delims== " %%a in ('type "C:\install\sirius_agent\sirius-atm.properties"^|find "path.images"') do (
  set pathresources=%%~a
 )
 call:writetolog "		Необходимо положить ресурсы в папку %pathresources:/=\%"
 rmdir /s /q "%pathresources:/=\%"
 mkdir "%pathresources:/=\%"
 call:writetolog "		Начинаем распаковку основных ресурсов в %pathresources%" >unpack_main_resources.log 2>&1
 call rar x resources.rar -o+ -y -idp -inul "%pathresources:/=\%"\ >>unpack_main_resources.log 2>&1
 call:writetolog "		Распаковка завершена." >>unpack_main_resources.log 2>&1
goto:EOF
 
@rem Завершение процесса установки
:finish
 @rem Проверяем, и при необходимости запускаем, сервис Tomcat
 net start|find /I "Tomcat7" > NUL 2>&1
 if not [%errorlevel%]==[0] call net start TomCat7 > NUL 2>&1

 call:writetolog "	Установка завершена."
 call:writetolog "****************************************************"
 @rem Ожидаем ~ 3 секунды.
 call:wait 3
 @rem Возвращаем переменные среды в исходное состояние
 call:prepareEnv 1
 exit
goto:EOF

@rem Получение размера RAM
:getRAMsize
 for /f "tokens=*" %%a in ('cscript /NOLOGO %wmicpath% os get TotalVisibleMemorySize') do (
  if not defined RAMSize set /A RAMSize=%%a/1024
 )
 call:writetolog "Объем доступной оперативной памяти = %RAMSize% Мб"
 set /A minRAMSize=%RAMSize%/64
 set /A maxRAMSize=%RAMSize%/4
 set /A midRAMSize=%RAMSize%/2
goto:EOF

@rem Описание допустимых параметров запуска скрипта
:help
 call:writetolog "****************************************************"
 call:writetolog " Синтаксис SETUP.CMD [параметр]"
 call:writetolog " параметры: java, tomcat, sirius, uninstall"
 call:writetolog " 	java	 	 - установка всего пакета = запуск без параметров"
 call:writetolog " 	tomcat	 	 - установка всего, кроме java"
 call:writetolog " 	sirius	 	 - установка только SIRIUS-ATM.WAR"
 call:writetolog " 	uninstall	 - удаление продукта."
 call:writetolog " 	uninstall silent - удаление без запросов."
 call:writetolog " 	help	 	 - это сообщение."
 call:writetolog "****************************************************"
 call:writetolog "Нажмите любую кнопку, что бы продолжить."
 pause >NUL
goto:EOF

@rem Блок установки JRE
:installJava
 call:setJavaName "Java Runtime 7 update 80"
 @rem Останавливаем сервис Tomcat
 net start|find /I "Tomcat7" && call net stop Tomсat7
 
 call:writetolog "	Установка %JAVAName%"
 call setup_jre.exe /s /v "/qn IEXPLORER=1 REBOOT=Suppress JAVAUPDATE=0 WEBSTARTICON=0 /L C:\install\sirius_agent\jre_install.log" > NUL 2>&1
 @rem Проверяем что JRE была установлена успешно.
 find /I "completed successfully" C:\install\sirius_agent\jre_install.log > NUL
 if [%errorlevel%]==[0] (
  @rem Устанавливаем перменную среды JAVA_HOME
  call:setEnvVar "JAVA_HOME" "%ProgramFiles%\Java\jre7"
  @rem Отключаем автозапуск JavaQuickStarterService
  net start|find /I "Java Quick Starter" && call net stop "Java Quick Starter" > NUL 2>&1
  sc config JavaQuickStarterService start= disabled
  call:writetolog "	%JAVAName% успешно установлен"
  exit /b 0
 ) else (
  call:writetolog "	Сбой установки %JAVAName%"
  @rem Назначем GUID установленной JRE
  if not defined currentGUID set currentGUID=2F0%osversion%17080FF
  @rem Вызываем блок отката установки JRE
  call:rollBack java
  call:writetolog "****************************************************"
  @rem Возвращаем переменные среды в исходное состояние
  call:prepareEnv 1
  goto:EOF
 )

@rem Блок установки СП Tomcat
:installTomcat
 call:writetolog "	Установка Apache TomCat 7.0.xx"
 @rem Если текущая версия Tomcat известна, значит надо сначала удалить сервис
 if not [%TOMCATVersion%]==[] call "%TOMCAT_HOME%\uninstall.exe" -ServiceName="Tomcat7" /S >NUL 2>&1
 @rem Запускаем молчаливую (/S) установку СП Tomcat
 call setup_tomcat.exe /S

 @rem Получение полного пути к первому экземпляру файла Tomcat7.exe начиная с папки %ProgramFiles% (включая вложенные)
 for /f "tokens=*" %%a in ('cscript /NOLOGO C:\install\sirius_agent\siriusTools.js getPath "Tomcat7.EXE" "%ProgramFiles%" false') do (set pathTomCat=%%a)
 
 @rem Установка переменной среды TOMCAT_HOME (два раза, на всякий случай, иногда не срабатывает даже так)
 if not defined TOMCAT_HOME call:setEnvVar "TOMCAT_HOME" "%pathTomCat%"
 if not defined TOMCAT_HOME set TOMCAT_HOME=%pathTomCat%
 
 @rem Вызов блока настройки СП Tomcat
 call:setupTomcat
 @rem Если установка и настройка прошли успешно
 if %errorlevel% equ 0 (
  call:writetolog "	Apache TomCat 7.0.xx успешно установлен"
  @rem Вызов блока установки клиентского приложения
  call:sirius
 )
goto:EOF

:java
 call:writetolog "----------------------------------------------------"
 call:writetolog "	Проверяем наличие установленной JRE."
 @rem Вызов блока проверки версии JRE
 call:checkJava 17080
 @rem Если версия JRE не соответствует заданной, устанавливаем необходимую версию
 if %errorlevel% equ 1 goto:installJava
 exit /b 0
goto:EOF

@rem Блок логирования исполнения команды, которая пытается выводить echo в консоль
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

@rem Блок подготовки переменных среды
:prepareEnv
 if [%1]==[0] (
    @rem Включаем CScript по-умолчанию, воизбежание и воисполнение
    call cscript //H:CScript >NUL 2>&1
	@rem Вызов блока установки региональных настроек
    call:setRegional
 )
 @rem Вызов блока проверки WMIC
 call:checkWMIC
 if [%errorlevel%]==[999] (
  set wmicpath=C:\install\sirius_agent\wmic.js
 ) else (
  set wmicpath=wmic
 )
 @rem Возвращаем HScript по-умолчанию, воизбежание и воисполнение
 if [%1]==[1] call cscript //H:WScript >NUL 2>&1
goto:EOF

@rem Блок обновления "особо вредных" переменных среды
:refreshVars
if defined CommonProgramW6432 (set osversion=64) else (set osversion=32)
if not defined currentGUID set currentGUID=2F0%osversion%17080FF
set "JAVA_HOME=%ProgramFiles%\Java\jre7"
goto:EOF

@rem Блок отката установки
:rollBack
 if [%1]==[tomcat] (
  @rem Останавливаем сервис Tomcat
  net start|find /I "Tomcat7" && call net stop Tomсat7
  
  @rem Удаление переменной среды SIRIUS_ATM_PROPERTIES
  call:setEnvVar "SIRIUS_ATM_PROPERTIES" "remove" remove
  call:writetolog "----------------------------------------------------"
  @rem Проверяем наличие запущенного трей-агента СП Tomcat и при необходимости останавливаем
  tasklist|find "tomcat7w.exe" && taskkill /F /IM tomcat7w.exe
  call:writetolog "	Отмена установки Apache TomCat 7.0.xx"
  @rem Удаление сервиса Tomcat
  call "%TOMCAT_HOME%\uninstall.exe" -ServiceName="Tomcat7" /S
  @rem Получение пути к Tomcat7w.lnk начиная с папки %ALLUSERSPROFILE% (включая вложенные)
  for /f "tokens=*" %%a in ('cscript /NOLOGO C:\install\sirius_agent\siriusTools.js getPath "Tomcat7w.lnk" "%ALLUSERSPROFILE%" true') do (
   @rem Если Tomcat7w.lnk существует, то удаляем
   if exist "%%a\Startup\Tomcat7w.lnk" del "%%a\StartUp\Tomcat7w.lnk" /Q /F > NUL 2>&1
  )
  @rem Удаление директории TOMCAT_HOME
  rd "%TOMCAT_HOME%" /s /q > NUL 2>&1
  @rem Удаление переменной среды TOMCAT_HOME
  call:setEnvVar "TOMCAT_HOME" "remove" remove
  @rem Удаление записей реестра сформированных (нативным) инсталлятором Tomcat
  @rem Автозапуск трей-агента
  reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "ApacheTomcatMonitor7.0_Tomcat7" /f >NUL 2>&1
  @rem Деинсталляция СП Tomcat
  reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Apache Tomcat 7.0 Tomcat7" /f >NUL 2>&1
  @rem Сервис СП Tomcat
  reg delete "HKLM\SYSTEM\CurrentControlSet\Services\Tomcat7" /f >NUL 2>&1
  @rem Настройки СП Tomcat
  reg delete "HKCU\Software\Apache Software Foundation" /f >NUL 2>&1
  @rem Запись о СП Tomcat в списке программ
  reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\MenuOrder\Start Menu\Programs\Apache Tomcat 7.0 Tomcat7" /f >NUL 2>&1
  @rem Настройки СП Tomcat
  reg delete "HKLM\SOFTWARE\Apache Software Foundation" /f >NUL 2>&1
  @rem Настройки сервиса СП Tomcat
  reg delete "HKLM\SYSTEM\ControlSet001\Enum\Root\LEGACY_TOMCAT7" /f >NUL 2>&1
  @rem Настройки сервиса СП Tomcat
  reg delete "HKLM\SYSTEM\ControlSet003\Enum\Root\LEGACY_TOMCAT7" /f >NUL 2>&1
  @rem Настройки сервиса СП Tomcat
  reg delete "HKLM\SYSTEM\CurrentControlSet\Enum\Root\LEGACY_TOMCAT7" /f >NUL 2>&1
  call:writetolog "	Установка Apache TomCat 7.0.xx отменена"
  @rem Вызов блока отката JRE
  call:rollBack java
 )
 if [%1]==[java] (
  @rem Вызов блока формирования GUID удаляемой версии JRE
  call:getJAVAGUID
  @rem Вызов блока формирования полной версии JRE
  call:setJavaName
  call:writetolog "----------------------------------------------------"
  call:writetolog "	Отмена установки %JAVAName%"
  @rem Удаление записи реестра автозапуска настроек агента СИРИУС после первой перезагрузки
  reg delete "HKLM\Software\Microsoft\Windows\CurrentVersion\RunOnce" /v "SirusAgent" /f >NUL 2>&1
  @rem Поиск, остановка и отключение автозапуска сервиса Java Quick Starter
  net start|find /I "Java Quick Starter" > NUL 2>&1
  if [%errorlevel%]==[0] (
   call net stop "Java Quick Starter" > NUL 2>&1
   sc config JavaQuickStarterService start= disabled
  )
  @rem Вызов блока деинсталляции JRE
  call:UninstallJAVA
  @rem Удаление переменной среды JAVA_HOME
  call:setEnvVar "JAVA_HOME" "remove" remove
  call:writetolog "	Установка %JAVAName% отменена"
 )
goto:EOF

@rem Блок установки переменных среды
:setEnvVar
 call:writetolog "	Системная переменная %~1"
 call:writetolog "	Значение переменной %~2"
 call:logCommand "cscript /NOLOGO C:\install\sirius_agent\siriusTools.js setEnvVar %~1 %~2 %~3"
goto:EOF

@rem Блок определения полной версии JRE
:setJavaName
 if not ["%~1"]==[""] (
  set JAVAName=%~1
 ) else (
  @rem Вызов блока определения GUID версии JRE
  call:getJAVAGUID
  for /f "tokens=3* skip=2" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{26A24AE4-039D-4CA4-87B4-%currentGUID%}" /v DisplayName') do (
   set JAVAName=%%a %%b
  )
 )
goto:EOF

@rem Блок принудительной установки региональных настроек - Россия
:setRegional
 rundll32.exe shell32,Control_RunDLL intl.cpl,,/f:"C:\install\sirius_agent\regionalSettings.ini"
goto:EOF

@rem Блок настройки СП Tomcat
:setupTomcat
 @rem Переход в директорию %TOMCAT_HOME%\bin\
 pushd "%TOMCAT_HOME%\bin\"
 @rem Вызов блока определения размера оперативной памяти
 call:getRAMsize
 @rem Вызов блока обновления значений критически важных переменных
 call:refreshVars

 call:writetolog "	Проверяем и останавливаем Tomcat"
 net start|find /I "Tomcat7" && call net stop Tomcat7
 call:writetolog "	Проверяем и останавливаем JRE"
 tasklist|find /I "java.exe" && taskkill /F /IM java.exe

 if exist Tomcat7.exe (
  call:writetolog "	Настраиваем используемую версию JRE"
  "Tomcat7.exe" //US//Tomcat7 --Jvm "%JAVA_HOME%\bin\client\jvm.dll"
  @rem В файле server.xml хранятся специфические (тонкие) настройки СП Tomcat
  call:writetolog "	Копирую файл настроек server.xml"
  xcopy /C /R /Y "C:\Install\sirius_agent\server.xml" "%TOMCAT_HOME%\conf\"|find /I %copied% 2>&1 && call:Tomcat7_1 "	Настройка кодировки UTF-8."
  
  @rem Service startup type <manual|auto>
  "Tomcat7.exe" //US//Tomcat7 --Startup auto 2>&1|find /I "[warn]" 2>&1 && goto:Tomcat7_0 "	Тип запуска сервиса = AUTO" && goto:EOF
  call:Tomcat7_1 "	Тип запуска сервиса = AUTO"
 
  @rem Initial memory pool size in MB 
  "Tomcat7.exe" //US//Tomcat7 --JvmMs %minRAMSize% 2>&1|find /I "[warn]" 2>&1 && goto:Tomcat7_0 "	Стартовый размер пула памяти в MB = %minRAMSize%" && goto:EOF
  call:Tomcat7_1 "	Стартовый размер пула памяти в MB = %minRAMSize%"

  @rem Maximum memory pool size in MB
  "Tomcat7.exe" //US//Tomcat7 --JvmMx %maxRAMSize% 2>&1|find /I "[warn]" 2>&1 && goto:Tomcat7_0 "	Максимальный размер пула памяти в MB = %maxRAMSize%" && goto:EOF
  call:Tomcat7_1 "	Максимальный размер пула памяти в MB = %maxRAMSize%"

  @rem Maximum Thread pool size in KB
  "Tomcat7.exe" //US//Tomcat7 --JvmSs %maxRAMSize% 2>&1|find /I "[warn]" 2>&1 && goto:Tomcat7_0 "	Максимальный размер пула потоков в КB = %maxRAMSize%" && goto:EOF
  call:Tomcat7_1 "	Максимальный размер пула потоков в KB = %maxRAMSize%"

  @rem Установка настроек JVM для СП Tomcat.
  "Tomcat7.exe" //US//Tomcat7 --JvmOptions "-server#-Dcatalina.base=%TOMCAT_HOME%#-Dcatalina.home=%TOMCAT_HOME%#-Djava.endorsed.dirs=%TOMCAT_HOME%\endorsed#-Djava.io.tmpdir=%TOMCAT_HOME%\temp#-Djava.net.preferIPv4Stack=true#-Djava.util.logging.config.file=%TOMCAT_HOME%\conf\logging.properties#-Djava.util.logging.manager=org.apache.juli.ClassLoaderLogManager#-Djavax.net.ssl.trustStore=%TOMCAT_HOME%\bin\sirius#-XX:+AggressiveOpts#-XX:+UseParallelGC#-XX:ParallelGCThreads=2" 2>&1|find /I "[warn]" 2>&1 && goto:Tomcat7_0 "	Настройка доверенного хранилища для TomCat" && goto:EOF
  call:Tomcat7_1 "	Настройка доверенного хранилища для TomCat"
	
  @rem Enable using of native Apache Tomcat APR. It should enable a high scalbility and performance.
  xcopy /C /R /Y "C:\Install\sirius_agent\tcnative-1.dll" "%TOMCAT_HOME%"|find /I %copied% 2>&1 && call:Tomcat7_1 "	Подключение нативной библиотеки APR."
  exit /b 0
 ) else (
  goto:Tomcat7_0 "	Неизвестная ошибка."
 )
 popd

goto:EOF

@rem Блок установки и настройки клиента СИРИУС
:sirius
 call:writetolog "	Проверяем и останавливаем Tomcat"
 net start|find /I "Tomcat7" && call net stop TomCat7
 call:writetolog "	Проверяем и останавливаем JRE"
 tasklist|find /I "java.exe" && taskkill /F /IM java.exe
 call:writetolog "----------------------------------------------------"
 call:writetolog "	Установка sirius-atm.war"
 @rem Удаление директории с распакованными рабочими версиями файлов
 if exist "%TOMCAT_HOME%\work" rd "%TOMCAT_HOME%\work" /s /q >NUL 2>&1
 @rem Удаление директории с распакованной версией клиента СИРИУС
 if exist "%TOMCAT_HOME%\webapps\sirius-atm" rd "%TOMCAT_HOME%\webapps\sirius-atm" /s /q >NUL 2>&1
 @rem Проверка существования WAR файла клиента СИРИУС
 if exist "C:\install\sirius_agent\sirius-atm.war" (
  @rem Копирование WAR файла клиента СИРИУС в директорию web-приложений СП Tomcat
  xcopy /C /R /Y "C:\install\sirius_agent\sirius-atm.war" "%TOMCAT_HOME%\webapps\"|find /I %copied% && call:writetolog "	sirius-atm.war - скопирован в папку WEBAPPS"
  @rem При наличии дополнительных модулей - копирование их в директорию lib СП Tomcat
  if exist "C:\install\sirius_agent\WEB-INF\lib" (
   call:writetolog "		Копирование модулей в lib"
   xcopy /S /C /R /Y "C:\install\sirius_agent\WEB-INF\lib\*.*" "%TOMCAT_HOME%\lib\"|find /I %copied%
   @rem Установка переменной среды CLASSPATH
   call:setEnvVar "CLASSPATH" "%TOMCAT_HOME%\lib"
   @rem Удаление директории с дополнительными модулями
   rd "C:\install\sirius_agent\WEB-INF" /s /q >NUL 2>&1
  )
  @rem Проверка существования файла настроек клиента СИРИУС
  if exist "C:\install\sirius_agent\sirius-atm.properties" (
   @rem Копирование файла настроек клиента СИРИУС в директорию web-приложений СП Tomcat
   xcopy /C /R /Y "C:\install\sirius_agent\sirius-atm.properties" "%TOMCAT_HOME%\webapps\"|find /I %copied% && call:writetolog "	sirius-atm.properties - скопирован в папку WEBAPPS"
   @rem Установка переменной среды SIRIUS_ATM_PROPERTIES
   call:setEnvVar "SIRIUS_ATM_PROPERTIES" "%TOMCAT_HOME%\webapps"
   @rem Вызов блока проверки наличия кэшированного экрана
   call:checkCached
   @rem Проверка существования архива с графическими ресурсами клиента СИРИУС
   if exist "C:\install\sirius_agent\resources.rar" (
    call:writetolog "	Найден архив с ресурсами"
	@rem Вызов блока распаковки архива с ресурсами
    call:copy_resources
   )
   
   @rem Проверка существования файла с внешним шрифтом
   if exist "C:\install\sirius_agent\fonts\PTRoubleSans.ttf" (
    call:writetolog "	Установка шрифта PTRoubleSans.ttf"
	@rem Установка и регистрация шрифта в ОС Windows
    call:logCommand "cscript /NOLOGO C:\install\sirius_agent\siriusTools.js installFont ^"PTRoubleSans.ttf^" ^"C:\install\sirius_agent\fonts^""
   ) else (
    call:writetolog "	WARN: Шрифт PTRoubleSans.ttf не найден."
   )
  )
  
  @rem Копируем файл доверенного хранилища в директорию %TOMCAT_HOME%\bin\
  if exist "%TOMCAT_HOME%\bin\sirius" call:writetolog "	Обновляем файл доверенного хранилища"
  xcopy /C /R /Y C:\install\sirius_agent\sirius "%TOMCAT_HOME%\bin\"|find /I %copied% > NUL 2>&1 && call:Tomcat7_1 "	Копирование файла доверенного хранилища"
  
  @rem Вызов блока настроек клиента привязанных к настройкам ЕГПО
  call:userSettings
  
  @rem Применение настроек реестра специфичных для текущего поставщика ППО (прибит гвоздями TellMe)
  if exist "C:\install\sirius_agent\%continue%.reg" regedit /s C:\install\sirius_agent\%continue%.reg
  
  @rem Применение настроек реестра специфичных для клиента СИРИУС
  if exist "C:\install\sirius_agent\sirius_agent.reg" regedit /s C:\install\sirius_agent\sirius_agent.reg
  call:writetolog "	Применяем настройки для работы со сценариями Самоинкассации"
  
  @rem Вызов блока настройки XML журнала для САМОИНКАССАЦИИ
  call:setFrontDataXML
  @rem Запись даты установки клиента СИРИУС в реестр
  reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Sirius agent" /v "InstallDate" /t REG_SZ /d "%YEAR%%MONTH%%DAY%" /f >NUL 2>&1
  call:writetolog "	SIRIUS-ATM.WAR успешно установлен"
 ) else (
  call:writetolog "	sirius-atm.war НЕ найден."
  call:writetolog "	Для удаления установленных продуктов: "
  call:writetolog "		1. JRE7"
  call:writetolog "		2. Apache Tomcat7"
  call:writetolog "	Выполнить setup.cmd uninstall"
  call:writetolog "****************************************************"
  @rem Ожидаем ~ 3 секунды
  call:wait 3
  @rem Возвращаем переменные среды в исходное состояние
  call:prepareEnv 1
 )
goto:EOF

@rem Блока деинсталляции клиента СИРИУС
:sUninstall
 call:writetolog "	Выполняется деинсталляция продукта SIRIUS."
 @rem Вызов блока отката установки Tomcat
 call:rollBack tomcat
 @rem Удаление лога установки JRE при наличии
 if exist C:\Install\sirius_agent\jre_install.log del C:\Install\sirius_agent\jre_install.log /s /q > NUL 2>&1
 @rem Удаление записи реестра из блока Установка и удаление программ
 reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Sirius agent" /f > NUL 2>&1

 call:writetolog "	Деинсталляция продукта завершена."
 call:writetolog "****************************************************"
 @rem Возвращаем переменные среды в исходное состояние
 call:prepareEnv 1 
 @rem Ожидаем ~ 3 секунды
 call:wait 3
 if [%~2]==[silent] goto:EOF 
 
 @rem Показываем окно с предупреждением о необходимости презагрузки
 for /f "tokens=*" %%a in ('cscript /NOLOGO C:\install\sirius_agent\isContinue.vbs "Необходимо произвести перезагрузку банкомата!"') do (
  if [%%a]==[_go_] (
   @rem Принудительная перезагрузка УС
   call:writetolog "	Пользователь выбрал принудительную перезугрузку банкомата."
   shutdown -r -t 00 -f
   goto:EOF
  )
 )
goto:EOF

@rem Блок установки СП Tomcat
:tomcat
 call:writetolog "----------------------------------------------------"
 @rem Установка переменной TEMP_TOMCAT_HOME
 for /f "tokens=*" %%a in ('cscript /NOLOGO C:\install\sirius_agent\siriusTools.js setEnvVar "TOMCAT_HOME"') do (set TEMP_TOMCAT_HOME=%%a)
 
 @rem Вызов блока проверки версии Tomcat
 call:checkTomcat 7.0.41
 @rem Установка или настройка Tomcat
 if [%updateTomcat%]==[true] goto:installTomcat
 if [%updateTomcat%]==[false] call:setupTomcat
 @rem Если установка или настройка Tomcat прошли успешно - вызов блока установки и настройки клиента СИРИУС
 if %errorlevel% equ 0 call:sirius
 exit /b 0
goto:EOF

@rem Блок отката установки Tomcat с записью в лог
:tomcat7_0
 call:writetolog "	%~1"
 call:writetolog "	Сбой установки Apache TomCat 7"
 @rem Вызов блока отката установки Tomcat
 call:rollBack tomcat
 call:writetolog "	Произведен откат изменений в системе"
 call:writetolog "****************************************************"
 @rem Ожидаем ~ 3 секунды
 call:wait 3
 @rem Возвращаем переменные среды в исходное состояние
 call:prepareEnv 1
 exit
goto:EOF

@rem Блок логирования установки настроек СП Tomcat
:tomcat7_1
 call:writetolog "	%~1"
 exit /b 0
goto:EOF

@rem Блок деинсталлирования клиента СИРИУС
:uninstall
 @rem Вызов блока проверки JRE
 call:checkJava 0
 @rem Если есть параметр silent - вызвать блок тихой деинсталляции
 if [%~2]==[silent] goto:sUninstall
 @rem Показываем окно с предупреждением о попытке удаления продукта
 for /f "tokens=*" %%a in ('cscript /NOLOGO C:\install\sirius_agent\isContinue.vbs "Вы собираетесь полностью удалить терминальный агент SIRIUS!"') do (
  if [%%a]==[stop] (
   @rem Прерываем деинсталляцию, если пользователь отказался
   call:writetolog "	Деинсталляция продукта не выполнена. Отказ пользователя."
   exit
  )
 )
@rem Безусловный преход в блок тихой деинсталляции
goto:sUninstall

@rem Блок установки настроек пользователя связанных с ЕГПО
:userSettings
 call:writetolog "	Подготовка настроек пользователя."
 @rem Проверяем не настроен ли вызов специфичных настроек ранее
 type c:\scs\atm_h\startup\vendor_start.bat|find "userSettings.bat" >NUL 2>&1
 if not [%errorlevel%]==[0] (
  call:writetolog "		Необходимо внести правки в настройки пользователя."
  echo. >>c:\scs\atm_h\startup\vendor_start.bat
  echo call c:\scs\atm_h\startup\userSettings.bat >> c:\scs\atm_h\startup\vendor_start.bat
  call:writetolog "		Изменен файл vendor_start.bat"
  echo. >c:\scs\atm_h\startup\userSettings.bat
  echo if exist "C:\install\sirius_agent\%continue%.reg" regedit /s C:\install\sirius_agent\%continue%.reg >>c:\scs\atm_h\startup\userSettings.bat
  call:writetolog "		Создан файл userSettings.bat"
 )
goto:EOF

@rem Блок ожидания (ping на 127.0.0.1 выполняется где-то секунду)
:wait
 ping -n %1 127.0.0.1 > NUL 2>&1
goto:EOF

@rem Блок записи в лог
:writetolog
 set logdata=%~1
 @echo %Date% %Time% %logdata%
 if [%STDOUT_REDIRECTED%]==[yes] @echo %Date% %Time% %logdata% > CON
goto:EOF

@rem Блок настроек NetBIOS
:netBIOSinfo
 call:logCommand "wmic nicconfig get caption, index, TcpipNetbiosOptions"
goto:EOF

:switchOn
@rem Включение NETBIOS
 if defined command call:setParams
 call:logCommand "wmic nicconfig where (TcpipNetbiosOptions=2) call SetTcpipNetbios 1"
goto:EOF

:switchOff
@rem Отключение NETBIOS
 call:logCommand "wmic nicconfig where (TcpipNetbiosOptions=1 OR TcpipNetbiosOptions=0) call SetTcpipNetbios 2"
goto:EOF

:setParams
rem Настройка NETBIOS
 @reg add "HKLM\SYSTEM\CurrentControlSet\Services\NetBT\Parameters" /v "NameSrvQueryCount" /t REG_DWORD /d 0x0 /f >NUL &&  call:writetolog "NameSrvQueryCount = 0"
 @reg add "HKLM\SYSTEM\CurrentControlSet\Services\NetBT\Parameters" /v "NameSrvQueryTimeout" /t REG_DWORD /d 0x1 /f >NUL && call:writetolog "NameSrvQueryTimeout = 1"
 @reg add "HKLM\SYSTEM\CurrentControlSet\Services\NetBT\Parameters" /v "BcastNameQueryCount" /t REG_DWORD /d 0x0 /f >NUL && call:writetolog "BcastNameQueryCount = 0" 
 @reg add "HKLM\SYSTEM\CurrentControlSet\Services\NetBT\Parameters" /v "BcastQueryTimeout" /t REG_DWORD /d 0x1 /f >NUL && call:writetolog "BcastQueryTimeout = 1"
goto:EOF


@rem Блок удаления JRE
:UninstallJAVA
for /f "usebackq skip=4 tokens=2*" %%i in (`@reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{26A24AE4-039D-4CA4-87B4-2F03217080FF}" /v "UninstallString"`) do ( 
 call %%j /qn /norestart
)
for /f "usebackq skip=4 tokens=2*" %%i in (`@reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{26A24AE4-039D-4CA4-87B4-2F83217080FF}" /v "UninstallString"`) do ( 
 call %%j /qn /norestart
)
goto:EOF

@rem Блок определения GUID версии JRE
:getJAVAGUID
 @reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{26A24AE4-039D-4CA4-87B4-2F8%osversion%%JAVAVersion%FF}" > NUL 2>&1
 if [%errorlevel%]==[0] (
  set currentGUID=2F8%osversion%%JAVAVersion%FF
 ) else (
  set currentGUID=2F0%osversion%%JAVAVersion%FF)
 )
goto:EOF

@rem Блок настройки XML журнала для САМОИНКАССАЦИИ
:setFrontDataXML
 set /a FrontDataXMLcount = 1
 reg query "HKCR\WOSA/XFS_ROOT\ATM\PaymentSystems\NDC\Protocol"|find "FrontDataXML"
 @rem Если найден раздел реестра, проверям сколько в нем уже есть записей
 if %errorlevel% equ 0 call :checkCount
 @rem Добавляем новую запись, если нужно
 if %FrontDataXMLcount% gtr 0 call :addParameter
goto:EOF

@rem Блок установки парамтеров XML журнала для САМОИНКАССАЦИИ в реестр
:addParameter
 call:writetolog "		Параметры не найдены. Применяем настройку."
 echo reg add "HKCR\WOSA/XFS_ROOT\ATM\PaymentSystems\NDC\Protocol\FrontDataXML\%FrontDataXMLcount%" /v "ParamName" /t REG_SZ /d "SUIT" /f
 echo reg add "HKCR\WOSA/XFS_ROOT\ATM\PaymentSystems\NDC\Protocol\FrontDataXML\%FrontDataXMLcount%" /v "ParamVarName" /t REG_SZ /d "SUIT_NUMBER" /f
goto:EOF

@rem Блок проверки количества парамтеров XML журнала для САМОИНКАССАЦИИ в реестре
:checkCount
 call:writetolog "		Найден раздел реестра FrontDataXML"
 for /f "tokens=8 delims=\" %%a in ('reg query "HKCR\WOSA/XFS_ROOT\ATM\PaymentSystems\NDC\Protocol\FrontDataXML" /f "*" /k^|find "FrontDataXML"') do (
  echo %%a
  if %FrontDataXMLcount% gtr 0 call:addNew %%a
 )
goto:EOF

@rem Блок добавления парамтера XML журнала для САМОИНКАССАЦИИ в реестре
:addNew
 reg query "HKCR\WOSA/XFS_ROOT\ATM\PaymentSystems\NDC\Protocol\FrontDataXML\%~1" /f "SUIT"
 if %errorlevel% equ 0 (
  call:writetolog "		Параметры уже настроены. Повторное применение пропущено."
  set /a FrontDataXMLcount=-1
 ) else (
  set /a FrontDataXMLcount=%FrontDataXMLcount%+1
 )
goto:EOF
