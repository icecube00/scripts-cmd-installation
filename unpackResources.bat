@echo off
call:writetolog "		�������� ���������� �������� ���� � %1"
call rar x resources.rar -ri1:100 -o+ -y -inul "%1"\
call:writetolog "		���������� ���������."
exit /b 0

:Writetolog
 set logdata=%~1
 @Echo %Date% %Time% %logdata%
 if [%STDOUT_REDIRECTED%]==[yes] @Echo %Date% %Time% %logdata% > CON
goto:EOF
