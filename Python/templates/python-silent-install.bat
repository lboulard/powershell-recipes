@SETLOCAL
@CD /D "%~dp0"
@SET PYVER=
@FOR %%f IN ("python-3.*-amd64.exe") DO @SET "PYVER=%%~nf"
@ECHO SET PYVER=%PYVER%
@IF NOT DEFINED PYVER (
ECHO ** ERROR: No Python installation program found
GOTO :NagUser
)
@IF NOT EXIST "%LOCALAPPDATA%\lboulard" MD "%LOCALAPPDATA%\lboulard"
@IF NOT EXIST "%LOCALAPPDATA%\lboulard\logs" MD "%LOCALAPPDATA%\lboulard\logs"
@
@IF "%1"=="uninstall" GOTO :Uninstall
@IF NOT EXIST "unattend.xml" (
ECHO **ERROR: unattend.xml file is missing
GOTO :NagUser
)
"%PYVER%.exe"^
 /passive^
 /log "%LOCALAPPDATA%\lboulard\logs\%PYVER%-install.log"
IF ERRORLEVEL 1 GOTO :NagUser
@GOTO :EOF
@:Uninstall
"%PYVER%.exe"^
 /uninstall^
 /passive^
 /log "%LOCALAPPDATA%\lboulard\logs\%PYVER%-uninstall.log"
@IF ERRORLEVEL 1 GOTO :NagUser
@GOTO :EOF
@
@:NagUser
@:: Pause if not interactive
@ECHO %cmdcmdline% | FIND /i "%~0" >NUL
@IF NOT ERRORLEVEL 1 PAUSE
