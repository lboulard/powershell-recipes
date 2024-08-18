@SETLOCAL
@CHCP 65001 >NUL:
@CD /D "%~dp0"
@IF ERRORLEVEL 1 @GOTO :Exit

@SET NAME=
@FOR %%f IN ("go1.*.windows-amd64.zip") DO @SET "NAME=%%~nxf"
@ECHO SET NAME=%NAME%
@IF NOT DEFINED NAME (
  @ECHO ** ERROR: go language installation program not found
  @CALL :errorlevel 64
  @GOTO :exit
)

@IF "%LBHOME%"=="" @(
  @ECHO/** ERROR Missing LBHOME environment variable
  @CALL :errorlevel 64
  @GOTO :exit
)

@IF "%GOPATH%"=="" @SET "GOPATH=%USERPROFILE%\go"

@CALL "%~dp0user-config.bat"

@IF "%1"=="uninstall" GOTO :Uninstall

@IF EXIST "%APPS%\go\." RD /Q /S "%APPS%\go\."

@where /Q pwsh.exe
@IF %ERRORLEVEL% EQU 0 (
  pwsh.exe -NoProfile -Command^
    "Expand-Archive -LiteralPath '%NAME%' -DestinationPath '%APPS%' -Force"
) ELSE @(
  PowerShell.exe -NoProfile -Command^
    "Expand-Archive -LiteralPath '%NAME%' -DestinationPath '%APPS%' -Force"
)
@IF ERRORLEVEL 1 @GOTO :Exit

@:: Pause if not interactive
@:exit
@SET ERR=%ERRORLEVEL%
@IF ERRORLEVEL 1 @ECHO Failure ERRORLEVEL=%ERRORLEVEL%
@TYPE NUL>NUL
@ECHO %cmdcmdline% | FIND /i "%~0" >NUL
@IF NOT ERRORLEVEL 1 PAUSE
@ENDLOCAL&EXIT /B %ERR%

@:Uninstall
@ECHO *ERROR not yet
@GOTO :EOF

:errorlevel
@EXIT /B %~1
