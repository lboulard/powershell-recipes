@SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
CD /D "%~dp0"
@IF ERRORLEVEL 1 GOTO :exit
@ECHO OFF

:: check if not admin
@fsutil dirty query %SYSTEMDRIVE% >nul 2>&1
@IF %ERRORLEVEL% EQU 0 (
  @ECHO This script shall run as current user.
  @CALL :errorlevel 128
  @GOTO :exit
)

IF "%LBPROGRAMS%" == "" @(
  ECHO ** ERROR, LBPROGRAMS envrironment variable not defined
  CALL :errorlevel 1
  GOTO :exit
)

SET VERSION=notfound
SET ARCHIVE=
FOR /D %%d IN ("xz-*") DO (
  FOR %%f IN ("%%d\xz-*-windows.zip") DO (
    FOR /F "tokens=2 delims=-" %%s IN ("%%~nf") DO (
      FOR /F "tokens=1-4 delims=." %%i IN ("%%s") DO (
        SET "m=%%i"
        CALL :version "!m:v=!" "%%j" "%%k" "%%l" "%%f"
      )
    )
  )
)

ECHO/VERSION=%VERSION%
IF %VERSION%==notfound (
 ECHO ** ERROR: No xz archive found
 CALL :errorlevel 64
 GOTO :exit
)
ECHO/ARCHIVE=%ARCHIVE%

SET POWERSHELL=PowerShell.exe
where /q pwsh.exe
IF %ERRORLEVEL% equ 0 SET POWERSHELL=pwsh.exe

@REM extract to tempoeary folder
SET "WORKDIR=%TEMP%\xz-%VERSION%"

ECHO ON
%POWERSHELL% -NoProfile -Ex Unrestricted -Command^
 "Expand-Archive -LiteralPath '%ARCHIVE%' -DestinationPath '%WORKDIR%' -Verbose -Force"
@IF ERRORLEVEL 1 GOTO :exit

@REM install 
@SET "OUTDIR=%WORKDIR%\bin_x86-64"
@SET "DEST=%LBPROGRAMS%\bin"

XCOPY /Y /R /B /J %OUTDIR%\*.exe "%DEST%\"
XCOPY /Y /R /B /J %OUTDIR%\*.dll "%DEST%\"

@RD /Q /S "%WORKDIR%"
@GOTO :exit

:version
SET "X=000000000%~1"
SET "Y=000000000%~2"
SET "Z=000000000%~3"
SET "P=000000000%~4"
SET "_VERSION=%X:~-8%.%Y:~-8%.%Z:~-8%.%P:~-8%"
IF %VERSION%==notfound GOTO :update
IF %_VERSION% GTR %__VERSION% GOTO :update
GOTO :EOF

:update
SET "__VERSION=%_VERSION%"
IF NOT "%~4"=="" (
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
SET "ARCHIVE=%~5"
GOTO :EOF

:exit
@ECHO OFF
:: Pause if not interactive
SET ERR=%ERRORLEVEL%
ECHO %cmdcmdline% | FIND /i "%~0" >NUL
IF NOT ERRORLEVEL 1 PAUSE
ENDLOCAL&EXIT /B %ERR%

:errorlevel
EXIT /B %~1
