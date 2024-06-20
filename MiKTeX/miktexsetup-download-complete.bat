@SETLOCAL
@CHCP 65001 >NUL:
@CD /D "%~dp0"
@IF ERRORLEVEL 1 GOTO :exit

:: check if not admin
@fsutil dirty query %SYSTEMDRIVE% >nul 2>&1
@IF %ERRORLEVEL% EQU 0 (
  @ECHO This script shall run as current user.
  @SETG ERRORLEVEL=64
  @GOTO :exit
)

@CALL ".\miktex-mirror.bat"

:: add --print-info-only for a dry run

".\miktexsetup_standalone.exe"^
 --verbose^
 --remote-package-repository="%URL%"^
 --local-package-repository="%~dp0CTAN"^
 --package-set=complete^
 download

:: (from installation) miktexsetup --verbose --shared=no uninstall

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
