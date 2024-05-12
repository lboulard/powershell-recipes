@SETLOCAL
@CHCP 65001 >NUL:
@CD /D "%~dp0"
@IF ERRORLEVEL 1 GOTO :exit

@SET PYTHON_INSTALL=
FOR /F "eol= delims=;" %%c IN ('py -3.12 -c "import os, sys; print(os.path.dirname(sys.executable))"') DO SET "PYTHON_INSTALL=%%c"

@ECHO SET PYTHON_INSTALL=%PYTHON_INSTALL%
@IF NOT DEFINED PYTHON_INSTALL @(
  ECHO ** ERROR: No Python 3.12 installation program found
  SET ERRORLEVEL=64
  GOTO :exit
)

:: check if admin
@fsutil dirty query %SYSTEMDRIVE% >nul 2>&1
@IF %ERRORLEVEL% NEQ 0 (
  @SET _ELEV=1
  @Powershell.exe "start cmd.exe -arg '/c """%~0"""' -verb runas" && GOTO :exit
  @ECHO This script needs admin rights.
  @ECHO To do so, right click on this script and select 'Run as administrator'.
  @GOTO :exit
)

@PATH %PYTHON_INSTALL%;%PATH%
PowerShell.exe -NoProfile -Command^
 "iwr -Uri https://bootstrap.pypa.io/get-pip.py -Outfile get-pip.py -UseBasicParsing"

python get-pip.py

@:: Pause if not interactive
@:exit
@SET ERR=%ERRORLEVEL%
@IF DEFINED _ELEV GOTO :_elev
@IF ERRORLEVEL 1 @ECHO Failure ERRORLEVEL=%ERRORLEVEL%
@SET ERRORLEVEL=0
@ECHO %cmdcmdline% | FIND /i "%~0" >NUL
@IF NOT ERRORLEVEL 1 PAUSE
@:_elev
@ENDLOCAL&EXIT /B %ERR%
