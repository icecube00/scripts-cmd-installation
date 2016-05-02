@echo off
set sirius_version=%~1
echo "DisplayVersion"="%sirius_version%">> sirius_agent.reg
::call rar a resources -ac -ep1 -r0 -u -ver[%sirius_version%] -y -s -idp -m5 @resources.arc >NUL
::call rar a main_resources -ac -ep1 -r0 -u -ver[%sirius_version%] -y -s -idp -m5 @main_resources.arc >NUL
call rar a sirius-install -ac -zsirius.cmn -u -ver[%sirius_version%] -y -s -sfx -idp -m5 @sirius.arc >NUL
if %errorlevel%==0 (
	exit /b 0
) else (
	exit /b 1
)
