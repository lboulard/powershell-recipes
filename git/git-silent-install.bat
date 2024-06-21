@SETLOCAL
CD /D "%~dp0"
@ECHO OFF

SET VERSION=notfound
SET PRG=
FOR %%f IN ("Git-*-64-bit.exe") DO (
  FOR /F "tokens=2 delims=-" %%s IN ("%%f") DO (
    FOR /F "tokens=1-3 delims=." %%i IN ("%%s") DO CALL :version "%%i" "%%j" "%%k" "%%f"
  )
)

ECHO/VERSION=%VERSION%
IF %VERSION%==notfound (
 ECHO ** ERROR: No Git installation program found
 CALL :errorlevel 64
 GOTO :exit
)
ECHO/PRG=%PRG%

IF "%1"=="uninstall" GOTO :Uninstall

@SET LOG=%LOCALAPPDATA%\lboulard\logs\git-install.log
@IF NOT EXIST "%LOCALAPPDATA%\lboulard" MD "%LOCALAPPDATA%\lboulard"
@IF NOT EXIST "%LOCALAPPDATA%\lboulard\logs" MD "%LOCALAPPDATA%\lboulard\logs"

ECHO ON

TASKKILL /F /IM "gpg-agent.exe" /T
TASKKILL /F /IM "ssh-pageant.exe" /T
TASKKILL /F /IM "git.exe" /T

@REM fully silent: /SUPPRESSMSGBOXES
START /WAIT %PRG% ^
 /SP- ^
 /SILENT ^
 /NORESTART ^
 /SUPPRESSMSGBOXES ^
 /CLOSEAPPLICATIONS ^
 /FORCECLOSEAPPLICATIONS ^
 /NORESTARTAPPLICATIONS ^
 /LOADINF=git-silent-install.inf ^
 /LOG=%LOG%

@ECHO OFF
GOTO :exit

@:Uninstall

ECHO ON
taskkill /F /IM ssh-pageant.exe
"%PROGRAMFILES%\Git\unins000.exe" ^
 /SP- ^
 /SILENT ^
 /SUPPRESSMSGBOXES ^
 /NORESTART ^
 /RESTARTAPPLICATIONS

@ECHO OFF
GOTO :exit

:version
SET "X=000000000%~1"
SET "Y=000000000%~2"
SET "Z=000000000%~3"
SET "__VERSION=%X:~-8%.%Y:~-8%.%Z:~-8%"
IF %VERSION%==notfound GOTO :update
IF %__VERSION% GTR %_VERSION% GOTO :update
GOTO :EOF

:update
SET "_VERSION=%__VERSION%"
SET "VERSION=%~1.%~2.%~3"
SET "PRG=%~4"
GOTO :EOF

:exit
:: Pause if not interactive
SET ERR=%ERRORLEVEL%
ECHO %cmdcmdline% | FIND /i "%~0" >NUL
IF NOT ERRORLEVEL 1 PAUSE
ECHO ON
@ENDLOCAL&EXIT /B %ERR%

:errorlevel
@EXIT /B %~1
