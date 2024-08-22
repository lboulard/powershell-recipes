@SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
@CHCP 65001 >NUL:
@CD /D "%~dp0"
@IF ERRORLEVEL 1 @GOTO :exit

@SET VERSION=notfound
@SET INSTALLER=
@FOR /D %%d IN ("go1*") DO @(
  FOR %%f IN ("%%d\go1*.windows-amd64.msi") DO @(
    FOR /F "tokens=1-3 delims=." %%i IN ("%%~nf") DO @(
      SET "m=%%i"
      CALL :version "!m:go=!" "%%j" "%%k" "" "%%f"
    )
  )
)

@ECHO/VERSION=%VERSION%
@IF "%VERSION%"=="notfound" @(
  @ECHO ** ERROR: go language installer not found
  @CALL :errorlevel 64
  @GOTO :exit
)
@ECHO/INSTALLER=%INSTALLER%


@SET LOG=%LOCALAPPDATA%\lboulard\logs\golang-install.log
@IF "%1"=="uninstall" GOTO :Uninstall

@IF NOT EXIST "%LOCALAPPDATA%\lboulard" MD "%LOCALAPPDATA%\lboulard"
@IF NOT EXIST "%LOCALAPPDATA%\lboulard\logs" MD "%LOCALAPPDATA%\lboulard\logs"

msiexec.exe /i "%INSTALLER%"^
 /QB /L*V "%LOG%"^
 /passive /norestart

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
@SET "INSTALLER=%~5"
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

@:Uninstall
msiexec.exe /x "%NAME%.msi"
