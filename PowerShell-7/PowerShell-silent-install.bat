@SETLOCAL
@CHCP 65001 >NUL:
@CD /D "%~dp0"
@IF ERRORLEVEL 1 GOTO :exit

@ECHO OFF
SET VERSION=notfound
SET ARCHIVE=
FOR %%f IN ("PowerShell-*.msi") DO (
  FOR /F "tokens=2 delims=-" %%v IN ("%%f") DO ( 
    FOR /F "tokens=1-3 delims=." %%i IN ("%%v") DO CALL :version "%%i" "%%j" "%%k" "%%f"
  )
)
ECHO/VERSION=%VERSION%
IF %VERSION%==notfound (
  SET ERRORLEVEL=128
  ECHO ** ERROR: No installation program found
  ECHO ON
  GOTO :exit
)
ECHO/ARCHIVE=%ARCHIVE%
ECHO ON

:: check if admin
@fsutil dirty query %SYSTEMDRIVE% >nul 2>&1
@IF %ERRORLEVEL% NEQ 0 (
  @SET _ELEV=1
  @Powershell.exe "start cmd.exe -arg '/c """%~0"""' -verb runas" && GOTO :exit
  @ECHO This script needs admin rights.
  @ECHO To do so, right click on this script and select 'Run as administrator'.
  @GOTO :exit
)

msiexec.exe /package %ARCHIVE%^
 /quiet^
 ADD_EXPLORER_CONTEXT_MENU_OPENPOWERSHELL=0^
 ADD_FILE_CONTEXT_MENU_RUNPOWERSHELL=1^
 ENABLE_PSREMOTING=0^
 REGISTER_MANIFEST=1^
 DISABLE_TELEMETRY=1^
 USE_MU=1^
 ENABLE_MU=1^
 ADD_PATH=1^
 REBOOT=ReallySuppres
@IF ERRORLEVEL 1 GOTO :exit

@:: Pause if not interactive
@:exit
@SET ERR=%ERRORLEVEL%
@IF DEFINED _ELEV GOTO :_elev
@IF ERRORLEVEL 1 @ECHO Failure ERRORLEVEL=%ERRORLEVEL%
@TYPE NUL>NUL
@ECHO %cmdcmdline% | FIND /i "%~0" >NUL
@IF NOT ERRORLEVEL 1 PAUSE
@:_elev
@ENDLOCAL&EXIT /B %ERR%

:version
SET "X=000000000%~1"
SET "Y=000000000%~2"
SET "Z=000000000%~3"
SET "__VERSION=%X:~-8%.%Y:~-8%.%Z:~-8%"
IF %VERSION%==notfound GOTO :update
IF %__VERSION% GTR %_VERSION% GOTO :update
GOTO :EOF

:update
SET "_VERSION=%__VERSION%"
SET "VERSION=%~1.%~2.%~3"
SET "ARCHIVE=%~4"
GOTO :EOF
