@SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
@CHCP 65001 >NUL:
@CD /D "%~dp0"
@IF ERRORLEVEL 1 @GOTO :exit

:: on folder argument, install latest version from this folder
:: else, try to install last version from all go1.* folders, then update APP\go
:: to latest version found.

:: from user perspective in explorer, just do a drag and drop folder on this
:: dosbatch. Junction folder in APP\go will not be changed.

@IF NOT "%~1"=="" @(
  @SET LINKFROMAPPS=
  @SET "FOLDERMATCH=%~1"
) ELSE @(
  @SET LINKFROMAPPS=1
  @SET FOLDERMATCH=go1*
)

@SET VERSION=notfound
@SET ARCHIVE=
@FOR /D %%d IN ("%FOLDERMATCH%") DO @(
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

@SET "GOFOLDER=go%VERSION%"
@FOR /F "tokens=1-2 delims=." %%i IN ("%VERSION%") DO @SET "GOBRANCH=%%i.%%j"

@IF NOT EXIST "%~dp0sdk-config.bat" GOTO :nouserconfig
@ECHO/** Reading user configuration "%~dp0sdk-config.bat"
CALL "%~dp0sdk-config.bat"
@IF ERRORLEVEL 1 @GOTO :exit
:nouserconfig

@IF DEFINED LINKFROMAPPS @(
  @IF "%APPS%"=="" @(
    @ECHO/** ERROR Missing APPS environment variable
    @CALL :errorlevel 64
    @GOTO :exit
  )
)

@IF "%GOPATH%"=="" @SET "GOPATH=%USERPROFILE%\go"
@IF "%GOSDK%"=="" @SET "GOSDK=%GOPATH%\sdk"

@SET "UTMPDIR=%GOSDK%\%GOFOLDER%_%TIME:~0,2%%TIME:~3,2%%TIME:~6,2%%TIME:~9,2%_%RANDOM%"

@ECHO Extracting to %GOSDK%\%GOFOLDER% (from %UTMPDIR%\go)

@IF EXIST "%GOSDK%\." GOTO :sdkcreated
MD "%GOSDK%"
@IF ERRORLEVEL 1 @GOTO :exit
:sdkcreated

@IF EXIST "%UTMPDIR%\go\."  @(
  @ECHO/** ERROR "%UTMPDIR%": folder exists
  @CALL :errorlevel 64
  @GOTO :exit
)

@where /Q pwsh.exe
@IF %ERRORLEVEL% EQU 0 (
  pwsh.exe -NoProfile -Command^
    "Expand-Archive -LiteralPath '%ARCHIVE%' -DestinationPath '%UTMPDIR%' -Force"
) ELSE @(
  PowerShell.exe -NoProfile -Command^
    "Expand-Archive -LiteralPath '%ARCHIVE%' -DestinationPath '%UTMPDIR%' -Force"
)

@REM Archive contains a "go" folder at root

@IF NOT EXIST "%UTMPDIR%\go\." @(
  @ECHO/** ERROR %UTMPDIR%\go: go installation not found
  @CALL :errorlevel 128
  @GOTO :exit
)

@REM Install in GOSDK\go1.x.y, folder "go" in extracted archive in UTMPDIR

@IF NOT EXIST "%GOSDK%\%GOFOLDER%\." GOTO :installfolder
RD /Q /S "%GOSDK%\%GOFOLDER%"
@IF ERRORLEVEL 1 @GOTO :exit
:installfolder
MOVE /Y "%UTMPDIR%\go" "%GOSDK%\%GOFOLDER%"
@IF ERRORLEVEL 1 @GOTO :exit
RD /Q /S "%UTMPDIR%
@IF ERRORLEVEL 1 @GOTO :exit

@REM Create GOSDK\go1.x junction to GOSDK\go1.x.y

@IF NOT EXIST "%GOSDK%\go%GOBRANCH%\." GOTO :linktofolder
fsutil.exe reparsepoint delete "%GOSDK%\go%GOBRANCH%"
RD /Q "%GOSDK%\go%GOBRANCH%"
@IF ERRORLEVEL 1 @GOTO :exit
:linktofolder
PUSHD "%GOSDK%
MKLINK /J "go%GOBRANCH%" "%GOFOLDER%"
POPD
@IF ERRORLEVEL 1 @GOTO :exit

@REM Create APP\go junction to GOSDK\go1.x.y

@IF DEFINED LINKFROMAPPS @(
  @IF NOT EXIST "%APPS%\go\." GOTO :applink
  fsutil.exe reparsepoint delete "%APPS%\go"
  RD /Q "%APPS%\go"
  @IF ERRORLEVEL 1 @GOTO :exit
  :applink
  MKLINK /J "%APPS%\go" "%GOSDK%\%GOFOLDER%"
  @IF ERRORLEVEL 1 @GOTO :exit
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

:errorlevel
@EXIT /B %~1
