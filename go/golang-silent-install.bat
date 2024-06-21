@SETLOCAL
@CHCP 65001 >NUL:
@CD /D "%~dp0"
@IF ERRORLEVEL 1 @GOTO :Exit

@SET NAME=
@FOR %%f IN ("go*.windows-amd64.msi") DO @SET "NAME=%%~nf"
@ECHO SET NAME=%NAME%
@IF NOT DEFINED NAME (
ECHO ** ERROR: go language installation program not found
GOTO :EOF
)

@SET LOG=%LOCALAPPDATA%\lboulard\logs\golang-install.log
@IF "%1"=="uninstall" GOTO :Uninstall

@IF NOT EXIST "%LOCALAPPDATA%\lboulard" MD "%LOCALAPPDATA%\lboulard"
@IF NOT EXIST "%LOCALAPPDATA%\lboulard\logs" MD "%LOCALAPPDATA%\lboulard\logs"

msiexec /i "%NAME%.msi"^
 /QB /L*V "%LOG%"^
 /passive /norestart
@GOTO :EOF

@:: Pause if not interactive
@:exit
@SET ERR=%ERRORLEVEL%
@IF ERRORLEVEL 1 @ECHO Failure ERRORLEVEL=%ERRORLEVEL%
@TYPE NUL>NUL
@ECHO %cmdcmdline% | FIND /i "%~0" >NUL
@IF NOT ERRORLEVEL 1 PAUSE
@ENDLOCAL&EXIT /B %ERR%

@:Uninstall
msiexec /x "%NAME%.msi"
