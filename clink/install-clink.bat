@SETLOCAL
@CHCP 65001 >NUL:
@CD /D "%~dp0"
@IF ERRORLEVEL 1 GOTO :exit

:: check if not admin
@fsutil dirty query %SYSTEMDRIVE% >nul 2>&1
@IF %ERRORLEVEL% EQU 0 (
  @ECHO This script shall run as current user.
  @CALL :errorlevel 128
  @GOTO :exit
)

@IF "%LBPROGRAMS%" == "" @(
  @ECHO ** ERROR, LBPROGRAMS envrironment variable not defined
  @CALL :errorlevel 1
  @GOTO :exit
)

@SET VERSION=notfound
@SET ARCHIVE=
@FOR %%f IN ("clink.*.zip") DO @(
  @FOR /F "tokens=2-4 delims=." %%i IN ("%%f") DO @CALL :version "%%i" "%%j" "%%k" "%%f"
)
@ECHO/VERSION=%VERSION%
@IF %VERSION%==notfound @(
  @ECHO ** ERROR, clink not found
  @SCALL :errorlevel 64
  @GOTO :exit
)

@where /q pwsh.exe
@IF %ERRORLEVEL% equ 0 (
pwsh.exe -NoProfile -Ex Unrestricted -Command "Expand-Archive -LiteralPath $env:ARCHIVE -DestinationPath $env:LBPROGRAMS\clink.$env:VERSION -Verbose -Force"
) ELSE (
powershell.exe -NoProfile -Ex Unrestricted -Command "Expand-Archive -LiteralPath $env:ARCHIVE -DestinationPath $env:LBPROGRAMS\clink.$env:VERSION -Verbose -Force"
)
IF EXIST "%LBPROGRAMS%\clink" RD "%LBPROGRAMS%\clink"
MKLINK /J "%LBPROGRAMS%\clink" "%LBPROGRAMS%\clink.%VERSION%"

@:: Pause if not interactive
@:exit
@SET ERR=%ERRORLEVEL%
@TYPE NUL>NUL
@ECHO %cmdcmdline% | FIND /i "%~0" >NUL
@IF NOT ERRORLEVEL 1 PAUSE
@ENDLOCAL&EXIT /B %ERR%

:version
@SET "X=000000000%~1"
@SET "Y=000000000%~2"
@SET "Z=000000000%~3"
@SET "__VERSION=%X:~-8%.%Y:~-8%.%Z:~-8%"
@IF %VERSION%==notfound GOTO :update
@IF %__VERSION% GTR %_VERSION% @GOTO :update
@GOTO :EOF

:update
@SET "_VERSION=%__VERSION%"
@SET "VERSION=%~1.%~2.%~3"
@SET "ARCHIVE=%~4"
@GOTO :EOF

:errorlevel
@EXIT /B %~1
