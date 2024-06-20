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

@SET PRG=
@FOR %%f IN ("basic-MiKTeX-*-x64.exe") DO @SET "PRG=%%~nxf"
@ECHO SET PRG=%PRG%
@IF NOT DEFINED PRG (
  @ECHO ** ERROR: No Basic MiKTeX installation program found
  @SET ERRORLEVEL=64
  @GOTO :exit
)

@CALL ".\miktex-mirror.bat"

:: add --dry-run for a dry run

".\%PRG%"^
 --unattended^
 --auto-install=yes^
 --remote-package-repository="%URL%"^
 --local-package-repository="%~dp0CTAN"^
 --user-config="%APPDATA%\MiKTeX"^
 --user-data="%LOCALAPPDATA%\MiKTeX"^
 --user-install="%LOCALAPPDATA%\Programs\MiKTeX"^
 --no-additional-roots^
 --package-set=basic^
 --paper-size=A4^
 --download-only^
 --private


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
