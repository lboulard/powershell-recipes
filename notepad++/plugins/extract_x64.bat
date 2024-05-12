@SETLOCAL ENABLEDELAYEDEXPANSION
@CD /D "%~dp0"

@SET ARCH=x64
@SET "DESTDIR=%ARCH%"

@SET "DSpellCheck_Archive=DSpellCheck_%ARCH%_*.zip"
@SET "NppExec_Archive=NppExec_*_dll_x64_PA.zip"

@CALL :mkdir "%DESTDIR%"

:: DSpellCheck extraction

@SET VERSION=notfound
@FOR %%f IN ("%DSpellCheck_Archive%") DO @(
  FOR /F "tokens=3 delims=_" %%v IN ("%%f") DO @(
    FOR /F "tokens=1-3 delims=." %%i IN ("%%v") DO @CALL :version "%%i" "%%j" "%%k" "%%f"
  )
)
@IF "%TARGET%"=="" @(
  @ECHO/ ** ERROR DSpellCheck not found
  @SET ERRORLEVEL=64
  @GOTO :exit
)

@ECHO.%TARGET% : %VERSION%
@CALL :extract "%TARGET%" "%DESTDIR%"
@IF ERRORLEVEL 1 @(
  @ECHO ** FAILURE detected
  @SET ERRORLEVEL=64
  @GOTO :exit
)
 
:: NppExec x86 extraction (for Notepad++ 7.6+)

@SET VERSION=notfound
@FOR %%f IN ("%NppExec_Archive%") DO @(
  FOR /F "tokens=2 delims=_" %%v IN ("%%f") DO @(
    SET "_=%%v" & CALL :version "!_:~0,1!" "!_:~1,1!" "!_:~2,1!" "%%f"
  )
)
@IF "%TARGET%"=="" @(
  @ECHO/ ** ERROR NppExec not found
  @SET ERRORLEVEL=64
  @GOTO :exit
)

@ECHO.%TARGET% : %VERSION%
@CALL :extract "%TARGET%" "%DESTDIR%"
@IF ERRORLEVEL 1 @(
  @ECHO ** FAILURE detected
  @SET ERRORLEVEL=64
  @GOTO :exit
)
 


:: Pause if not interactive
@SET ERR=%ERRORLEVEL%
@ECHO %cmdcmdline% | FIND /i "%~0" >NUL
@IF NOT ERRORLEVEL 1 PAUSE
@ENDLOCAL&SET ERRORLEVEL=%ERR%
@GOTO :EOF

:install
@SETLOCAL
@SET "DEST=%~1"
@CALL :mkdir "%DEST%"
@FOR %%F IN (%2 %3 %4 %5 %6 %7 %8 %9) DO @(
CALL :copy "x86\%%~F" "%DEST%\"
IF ERRORLEVEL 1 @GOTO :return
)
:return
@ENDLOCAL&GOTO :EOF

:copy
xcopy /Z /H /J /Y /V /S "%~1" "%~2"
@GOTO :EOF

:mkdir
@IF NOT EXIST "%~1\." MD "%~1"
@GOTO :EOF

:extract
@ECHO %~1 : extracting
@PowerShell -NoProfile -Command "Expand-Archive -Path '%~1' -DestinationPath '%~2' -Force"
@GOTO :EOF

:version
@SET "X=000000000%~1"
@SET "Y=000000000%~2"
@SET "Z=000000000%~3"
@SET "__VERSION=%X:~-8%.%Y:~-8%.%Z:~-8%"
@IF %VERSION%==notfound GOTO :update
@IF %__VERSION% GTR %_VERSION% GOTO :update
@GOTO :EOF

:update
@SET "_VERSION=%__VERSION%"
@SET "VERSION=%~1.%~2.%~3"
@SET "TARGET=%~4"
@GOTO :EOF
