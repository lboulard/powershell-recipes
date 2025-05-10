@SETLOCAL ENABLEEXTENSIONS

@CALL "%~dp0..\bin\getfetchlocation.bat" "vim-lboulard"
CD /D "%LOCATION%"
@ECHO OFF
@IF ERRORLEVEL 1 GOTO :exit

SET VERSION=notfound
SET PRG=
FOR %%f IN ("gvim-*-amd64.exe") DO (
  FOR /F "tokens=2 delims=-" %%v IN ("%%f") DO (
    FOR /F "tokens=1-3 delims=." %%i IN ("%%v") DO CALL :version "%%i" "%%j" "%%k" "%%f"
  )
)
ECHO/VERSION=%VERSION%
IF %VERSION%==notfound GOTO exit
ECHO/PRG=%PRG%

"%PRG%" /S

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
SET ERR=%ERRORLEVEL%
:: Pause if not interactive
ECHO %cmdcmdline% | FIND /i "%~0" >NUL
IF NOT ERRORLEVEL 1 PAUSE
ENDLOCAL&EXIT /B %ERR%
