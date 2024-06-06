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


@SET RBINST=
@FOR %%f IN ("rubyinstaller-3.*-x64.exe") DO @SET "RBINST=%%~f"
@ECHO SET RBINST=%RBINST%
@IF NOT DEFINED RBINST (
  @ECHO ** ERROR: No Ruby installation program found
  @SET ERRORLEVEL=64
  @GOTO :exit
)

@IF NOT EXIST "%LOCALAPPDATA%\lboulard\logs\."^
 MD "%LOCALAPPDATA%\lboulard\logs"
@::IF ERRORLEVEL 1 GOTO :exit

@SET "RBVER=Ruby3%RBINST:~16,1%"
@SET "DEST=%LBHOME%\..\Apps\%RBVER%-x64"
@CALL :expand "%DEST%"
@SET "DEST=%RETVAL%"

".\%RBINST%" /SILENT /CURRENTUSER ^
 /TASKS="modpath,assocfiles,noridkinstall,defaultutf8"^
 /LOG="%LOCALAPPDATA%\lboulard\logs\%RBVER%-Install.log"^
 /COMPONENTS=ruby,rdoc^
 /DIR="%DEST%"


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

@:expand
@SET "RETVAL=%~dpf1"
@GOTO :EOF