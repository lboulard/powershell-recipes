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
@FOR %%f IN ("uncrustify-*.zip") DO @(
  @FOR /F "tokens=2 delims=-_" %%v IN ("%%f") DO @(
    @FOR /F "tokens=1-3 delims=." %%i IN ("%%v") DO @CALL :version "%%i" "%%j" "%%k" "%%f"
  )
)
@ECHO/VERSION=%VERSION%
@IF %VERSION%==notfound @(
  @ECHO ** ERROR, dirx not found
  @SCALL :errorlevel 64
  @GOTO :exit
)
@ECHO/ARCHIVE=%ARCHIVE%

@SET POWERSHELL=PowerShell.exe
@where /q pwsh.exe
@IF %ERRORLEVEL% equ 0 SET POWERSHELL=pwsh.exe

@SET "DEST=%LBPROGRAMS%\Apps\uncrustify-%VERSION%"
@SET "BIN=%LBPROGRAMS%\bin\uncrustify.exe"
@IF EXIST "%DEST%\." RD /Q /S "%DEST%"
@IF ERRORLEVEL 1 GOTO :exit
::MD "%DEST%:
::@IF ERRORLEVEL 1 GOTO :exit

%POWERSHELL% -NoProfile -Ex Unrestricted -Command^
 "Expand-Archive -LiteralPath $Env:ARCHIVE -DestinationPath $Env:DEST -Verbose -Force"
@IF ERRORLEVEL 1 GOTO :exit

@IF EXIST "%BIN%" @DEL /F "%BIN%
MKLINK /H "%BIN%" "%DEST%\bin\uncrustify.exe"

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
