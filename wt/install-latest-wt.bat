@SETLOCAL

@CALL "%~dp0..\bin\getfetchlocation.bat" "microsoft-terminal"
CD /D "%LOCATION%"
@ECHO OFF

SET VERSION=notfound
SET ARCHIVE=
FOR %%f IN ("Microsoft.WindowsTerminal_*_8wekyb3d8bbwe.msixbundle") DO (
  FOR /F "tokens=2 delims=_" %%s IN ("%%f") DO (
    FOR /F "tokens=1-4 delims=." %%i IN ("%%s") DO CALL :version "%%i" "%%j" "%%k" "%%l" "%%f"
  )
)

ECHO/VERSION=%VERSION%
IF %VERSION%==notfound (
 CALL :errorlevel 64
 GOTO :exit
)
ECHO/ARCHIVE=%ARCHIVE%

ECHO ON
Powershell -noprofile -Command Add-AppxPackage -Path "%ARCHIVE%"
@ECHO OFF
@GOTO :exit

:version
SET "X=000000000%~1"
SET "Y=000000000%~2"
SET "Z=000000000%~3"
SET "P=000000000%~4"
SET "__VERSION=%X:~-8%.%Y:~-8%.%Z:~-8%.%P:~-8%"
IF %VERSION%==notfound GOTO :update
IF %__VERSION% GTR %_VERSION% GOTO :update
GOTO :EOF

:update
SET "_VERSION=%__VERSION%"
SET "VERSION=%~1.%~2.%~3.%~4"
SET "ARCHIVE=%~5"
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
