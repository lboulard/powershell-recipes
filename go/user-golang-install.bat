@SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
@CHCP 65001 >NUL:
@CD /D "%~dp0"
@IF ERRORLEVEL 1 @GOTO :exit

@SET VERSION=notfound
@SET ARCHIVE=
@FOR /D %%d IN ("go1*") DO @(
  FOR %%f IN ("%%d\go1*.windows-amd64.zip") DO @(
    FOR /F "tokens=1-3 delims=." %%i IN ("%%~nf") DO @(
      SET "m=%%i"
      CALL :version "!m:go=!" "%%j" "%%k" "" "%%f"
    )
  )
)

@ECHO/VERSION=%VERSION%
@IF "%VERSION%"=="notfound" @(
  @ECHO ** ERROR: go language archive not found
  @CALL :errorlevel 64
  @GOTO :exit
)
@ECHO/ARCHIVE=%ARCHIVE%

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
    "Expand-Archive -LiteralPath '%ARCHIVE%' -DestinationPath '%APPS%' -Force"
) ELSE @(
  PowerShell.exe -NoProfile -Command^
    "Expand-Archive -LiteralPath '%ARCHIVE%' -DestinationPath '%APPS%' -Force"
)

@GOTO :exit

:version
@SET "X=000000000%~1"
@SET "Y=000000000%~2"
@SET "Z=000000000%~3"
@SET "P=000000000%~4"
@SET "_VERSION=%X:~-8%.%Y:~-8%.%Z:~-8%.%P:~-8%"
@IF %VERSION%==notfound GOTO :update
@IF %_VERSION% GTR %__VERSION% GOTO :update
@GOTO :EOF

:update
@SET "__VERSION=%_VERSION%"
@IF NOT "%~4"=="" (
  SET "VERSION=%~1.%~2.%~3.%~4"
) ELSE (
  IF NOT "%~3"=="" (
    SET "VERSION=%~1.%~2.%~3"
  ) ELSE (
    IF NOT "%~2"=="" (
      SET "VERSION=%~1.%~2"
    ) ELSE (
      SET "VERSION=%~1"
    )
  )
)
@SET "ARCHIVE=%~5"
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
@ECHO *ERROR not yet
@GOTO :EOF

:errorlevel
@EXIT /B %~1
