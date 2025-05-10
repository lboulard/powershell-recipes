@SETLOCAL

@CALL "%~dp0..\bin\getfetchlocation.bat" "win32-openssh"

msiexec /i "%LOCATION%\OpenSSH-Win64.msi" ADDLOCAL=Client

@SET ERR=%ERRORLEVEL%
@TYPE NUL>NUL
@ECHO %cmdcmdline% | FIND /i "%~0" >NUL
@IF NOT ERRORLEVEL 1 PAUSE
@ENDLOCAL&EXIT /B %ERR%
