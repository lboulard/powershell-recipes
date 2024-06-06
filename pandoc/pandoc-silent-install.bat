@SETLOCAL
CD /D "%~dp0"
@ECHO OFF

SET VERSION=notfound
SET PRG=
FOR /D %%d IN ("pandoc-*") DO (
  FOR %%f IN ("%%d\pandoc-*-windows-x86_64.msi") DO (
    FOR /F "tokens=2 delims=-" %%s IN ("%%~nf") DO (
      FOR /F "tokens=1-4 delims=." %%i IN ("%%s") DO CALL :version "%%i" "%%j" "%%k" "%%l" "%%f"
    )
  )
)

ECHO/VERSION=%VERSION%
IF %VERSION%==notfound (
 ECHO ** ERROR: No pandoc installation program found
 CALL :errorlevel 64
 GOTO :exit
)
ECHO/PRG=%PRG%

IF NOT EXIST "%LOCALAPPDATA%\lboulard" MD "%LOCALAPPDATA%\lboulard"
IF NOT EXIST "%LOCALAPPDATA%\lboulard\logs" MD "%LOCALAPPDATA%\lboulard\logs"

IF "%1"=="uninstall" GOTO :Uninstall
ECHO ON

msiexec /i "%PRG%"^
 /QB /L*V "%LOCALAPPDATA%\lboulard\logs\pandoc-%VERSION%-install.log"^
 /passive /norestart^
 ALLUSERS=2

@ECHO OFF
GOTO :exit

:Uninstall
ECHO ON

msiexec /x "%PRG%"^
 /QB /L*V "%LOCALAPPDATA%\lboulard\logs\pandoc-%VERSION%-uninstall.log"

@ECHO OFF
GOTO :exit

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
SET "PRG=%~5"
GOTO :EOF

:exit
:: Pause if not interactive
SET ERR=%ERRORLEVEL%
ECHO %cmdcmdline% | FIND /i "%~0" >NUL
IF NOT ERRORLEVEL 1 PAUSE
ECHO ON
ENDLOCAL&EXIT /B %ERR%

:errorlevel
EXIT /B %~1
