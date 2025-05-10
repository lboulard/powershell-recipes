@SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

@CALL "%~dp0..\bin\getfetchlocation.bat" "chezmoi"
CD /D "%LOCATION%"
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
FOR /D %%d IN ("chezmoi-*") DO (
  FOR %%f IN ("%%d\chezmoi_*_windows_%PROCESSOR_ARCHITECTURE%.zip") DO (
    FOR /F "tokens=2 delims=_" %%s IN ("%%~nf") DO (
      FOR /F "tokens=1-4 delims=." %%i IN ("%%s") DO (
        CALL :version "%%i" "%%j" "%%k" "%%l" "%%f"
      )
    )
  )
)

ECHO/VERSION=%VERSION%
IF %VERSION%==notfound (
 ECHO ** ERROR: No chezmoi archive found
 CALL :errorlevel 64
 GOTO :exit
)
ECHO/ARCHIVE=%ARCHIVE%

SET POWERSHELL=PowerShell.exe
where /q pwsh.exe
IF %ERRORLEVEL% equ 0 SET POWERSHELL=pwsh.exe

SET "WORKDIR=%TEMP%\chezmoi-%VERSION%"
SET "OUTDIR=%TEMP%\chezmoi-%VERSION%"
SET "BINEXE=%OUTDIR%\chezmoi.exe"

SET "DEST=%LBPROGRAMS%\local\bin"
SET "BIN=%DEST%\chezmoi-%VERSION%.exe"
SET "BINLINK=%DEST%\chezmoi.exe"

@REM Extract archive in %TEMP%\chezmoi-%VERSION%
@REM Copy chezmoi.exe as chezmoi-%VERSION%.exe in destination
@REM Create hardlink from chezmoi.exe to chezmoi-%VERSION%.exe in destination

ECHO ON
%POWERSHELL% -NoProfile -Ex Unrestricted -Command^
 "Expand-Archive -LiteralPath '%ARCHIVE%' -DestinationPath '%WORKDIR%' -Verbose -Force"
@IF ERRORLEVEL 1 GOTO :exit

COPY /Y "%BINEXE%" "%BIN%"
@IF ERRORLEVEL 1 GOTO :exit
@RD /Q /S "%OUTDIR%"

@IF EXIST "%BINLINK%" DEL /Q /F "%BINLINK%"
@IF ERRORLEVEL 1 GOTO :exit

MKLINK /H "%BINLINK%" "%BIN%"

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
