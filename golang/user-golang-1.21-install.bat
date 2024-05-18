@SETLOCAL
@CHCP 65001 >NUL:
@CD /D "%~dp0"
@IF ERRORLEVEL 1 @GOTO :Exit

@SET NAME=
@FOR %%f IN ("go1.21*.windows-amd64.zip") DO @SET "NAME=%%~nxf"
@ECHO SET NAME=%NAME%
@IF NOT DEFINED NAME (
  @ECHO ** ERROR: go language installation program not found
  @CALL :errorlevel 64
  @GOTO :exit
)

@FOR /F "usebackq delims=. tokens=1-3" %%x IN ('%NAME:~2%') DO @SET "VERSION=%%x.%%y.%%z"
@ECHO SET VERSION=%VERSION%

@IF "%LBHOME%"=="" @(
  @ECHO/** ERROR Missing LBHOME environment variable
  @CALL :errorlevel 64
  @GOTO :exit
)

@CALL "%~dp0user-config.bat"
@SET "DEST=%GOSDK%\go%VERSION%"

@IF "%1"=="uninstall" GOTO :Uninstall

@IF EXIST "%DEST%\." RD /Q /S "%DEST%"
@IF EXIST "%GOSDK%\go\." RD /Q /S "%GOSDK%\go"
@IF NOT EXIST "%APPS%\go\." MD "%APPS%\go"
@IF NOT EXIST "%APPS%\go\bin\." MD "%APPS%\go\bin"

@IF ERRORLEVEL 1 @GOTO :Exit

@where /Q pwsh.exe
@IF %ERRORLEVEL% EQU 0 (
  pwsh.exe -NoProfile -Command^
    "Expand-Archive -LiteralPath '%NAME%' -DestinationPath '%GOSDK%' -Force"
) ELSE @(
  PowerShell.exe -NoProfile -Command^
    "Expand-Archive -LiteralPath '%NAME%' -DestinationPath '%GOSDK%' -Force"
)
@IF ERRORLEVEL 1 @GOTO :Exit

MOVE /Y "%GOSDK%\go" "%DEST%"
COPY /Y "%DEST%\bin\go.exe" "%APPS%\go\bin\go%VERSION%.exe"

@IF ERRORLEVEL 1 @GOTO :Exit

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

@:Uninstall
@IF EXIST "%APPS%\go\bin\go%VERSION%.exe" DEL /S "%APPS%\go\bin\go%VERSION%.exe"
@IF EXIST "%DEST%\." RD /Q /S "%DEST%
@GOTO :EOF

:errorlevel
@EXIT /B %~1
