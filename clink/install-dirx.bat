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

@IF "%LBPROGRAMS%" == "" @(
  @ECHO ** ERROR, LBPROGRAMS envrironment variable not defined
  @SETG ERRORLEVEL=64
  @GOTO :exit
)

@SET ARCHIVE=
@FOR %%f IN ("dirx-*.zip") DO @SET "ARCHIVE=%%~nxf"
@ECHO SET ARCHIVE=%ARCHIVE%
@IF NOT DEFINED ARCHIVE (
  @ECHO ** ERROR, dirx archive not found
  @SET ERRORLEVEL=64
  @GOTO :exit
)

@SET POWERSHELL=PowerShell.exe
@where /q pwsh.exe
@IF %ERRORLEVEL% equ 0 SET POWERSHELL=pwsh.exe

%POWERSHELL% -NoProfile -Ex Unrestricted -Command^
 "Expand-Archive -LiteralPath '%ARCHIVE%' -DestinationPath '%LBPROGRAMS%\bin' -Verbose -Force"
@IF ERRORLEVEL 1 GOTO :exit

@:: Pause if not interactive
@:exit
@SET ERR=%ERRORLEVEL%
@SET ERRORLEVEL=0
@ECHO %cmdcmdline% | FIND /i "%~0" >NUL
@IF NOT ERRORLEVEL 1 PAUSE
@ENDLOCAL&EXIT /B %ERR%

