@SETLOCAL
@ECHO OFF
@CALL "%~dp0..\bin\getfetchlocation.bat" "microsoft-terminal"
CD /D "%LOCATION%"

SET VERSION=notfound
SET ARCHIVE=
FOR %%f IN ("Microsoft.WindowsTerminal_*_8wekyb3d8bbwe.msixbundle") DO (
  FOR /F "tokens=2 delims=_" %%s IN ("%%f") DO (
    FOR /F "tokens=1-4 delims=." %%i IN ("%%s") DO CALL :version "%%i" "%%j" "%%k" "%%l" "%%f"
  )
)

IF %VERSION%==notfound (
  ECHO/VERSION=%VERSION%
  CALL :errorlevel 64
  GOTO :exit
)

CALL :sha256 MSIX_SHA256 "Microsoft.WindowsTerminal_%VERSION%_8wekyb3d8bbwe.msixbundle"
CALL :sha256 ZIP_SHA256  "Microsoft.WindowsTerminal_%VERSION%_x64.zip"
CALL :output_file OUTFILE "%~dpn0"
ECHO.Writing to %OUTFILE%
CALL :template >"%OUTFILE%"
GOTO :exit

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

:sha256
:: <ENV NAME> <FILE NAME>
SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
SET "FILE=%~2"
FOR /F "usebackq delims=" %%h IN (`CertUtil.exe -hashfile "%FILE%" SHA256 ^| findstr /v hash`) DO SET SHA256=%%h
:: Ugly trick for uppercase using FIND error message
FOR /F "tokens=5 delims= " %%u IN ('FIND "" "%SHA256%" 2^>^&1') DO SET SHA256=%%u
ENDLOCAL & SET "%~1=%SHA256%"
GOTO :EOF

:output_file
SET "%~1=%~dpn2"
GOTO :EOF

:template
:: by default empty lines are lost, prefix with line number to avoid empty line
FOR /F "tokens=1,* delims=]" %%f in ('type "%~dpn0" ^| find /v /n ""') DO (
  CMD /D /Q /S /C "ECHO.%%g"
)
GOTO :EOF
