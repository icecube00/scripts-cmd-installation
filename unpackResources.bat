@echo off
call:writetolog "		Начинаем распаковку ресурсов ЕРИБ в %1"
call rar x resources.rar -ri1:100 -o+ -y -inul "%1"\
call:writetolog "		Распаковка завершена."
exit /b 0

:Writetolog
 set logdata=%~1
 @Echo %Date% %Time% %logdata%
 if [%STDOUT_REDIRECTED%]==[yes] @Echo %Date% %Time% %logdata% > CON
goto:EOF
